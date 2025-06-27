#!/usr/bin/env bash
# nuke-account.sh — delete almost everything except ACM, Secrets Manager, KMS.
# DRY_RUN=true ./nuke-account.sh        (show what would be deleted)
# DRY_RUN=false ./nuke-account.sh -f    (delete without prompts)

set -euo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) || true
[[ $ACCOUNT_ID != "851725384896" ]] && { echo "❌ Wrong account ($ACCOUNT_ID)"; exit 1; }
REGION=${AWS_REGION:-us-east-1} 
SAFE_SERVICES=(acm secretsmanager kms)
DRY_RUN=${DRY_RUN:-true}
FORCE=${1:-}

REGIONS=($(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)) || true
cyan() { echo -e "\033[1;36m$*\033[0m"; }
warn() { echo -e "⚠️ $*"; }

aws_ec2() { aws ec2 "$@" --region "$REGION" --no-cli-pager; }

#######################################
delete_arn () {
  local ARN=$1
  IFS=: read -r _ _ SVC REGION _ RES <<< "$ARN"

  # skip protected services
  for SAFE in "${SAFE_SERVICES[@]}"; do
    [[ $SVC == "$SAFE" ]] && { warn " ⏭️  Skip $ARN (protected)"; return; }
  done

  [[ $DRY_RUN == true ]] && { echo " DRY ⇒ $ARN"; return; }

  case $SVC in
    ec2)
      case $RES in
        instance/*)          aws_ec2 terminate-instances --instance-ids "${RES#instance/}" || true ;;
        volume/*)            aws_ec2 delete-volume --volume-id "${RES#volume/}" ;;
        elastic-ip/*)        aws_ec2 release-address --allocation-id "${RES#elastic-ip/}" ;;
        natgateway/*)        aws_ec2 delete-nat-gateway --nat-gateway-id "${RES#natgateway/}" ;;
        network-interface/*) aws_ec2 delete-network-interface --network-interface-id "${RES#network-interface/}" ;;
        security-group/*)    aws_ec2 delete-security-group --group-id "${RES#security-group/}" || true ;;
        network-acl/*)       ACL_ID=${RES#network-acl/}
    IS_DEFAULT=$(aws_ec2 describe-network-acls \
                   --network-acl-ids "$ACL_ID" \
                   --query 'NetworkAcls[0].IsDefault' --output text 2>/dev/null)
    [[ $IS_DEFAULT == "true" ]] && { warn "   ⏭️  Skip default ACL $ACL_ID"; break; }
    aws_ec2 delete-network-acl --network-acl-id "$ACL_ID" || true ;;
        route-table/*)       aws_ec2 delete-route-table --route-table-id "${RES#route-table/}" || true ;;
        internet-gateway/*)  aws_ec2 delete-internet-gateway --internet-gateway-id "${RES#internet-gateway/}" || true ;;
        subnet/*)            aws_ec2 delete-subnet --subnet-id "${RES#subnet/}" || true ;;
        launch-template/*)   aws_ec2 delete-launch-template --launch-template-id "${RES#launch-template/}" ;;
        vpc/*)               warn "   👉 use dedicated VPC cleanup for ${RES#vpc/}" ;;
        *)                   warn "   ⚠️  Unhandled ec2 resource $RES" ;;
      esac ;;
    elasticloadbalancing|elbv2)
      case $RES in
        loadbalancer/*)  aws elbv2 delete-load-balancer --load-balancer-arn "$ARN" --region "$REGION" ;;
        targetgroup/*)   aws elbv2 delete-target-group  --target-group-arn  "$ARN" --region "$REGION" ;;
        listener/*)      aws elbv2 delete-listener      --listener-arn      "$ARN" --region "$REGION" ;;
        *) warn "   ⚠️ Unhandled ELB resource $RES" ;;
      esac ;;
    eks)
      case $RES in
        cluster/*)    aws eks delete-cluster --name "${RES#cluster/}" --region "$REGION" ;;
        nodegroup/*)  IFS=/ read -r _ CL NG _ <<< "$RES"; aws eks delete-nodegroup --cluster-name "$CL" --nodegroup-name "$NG" --force --region "$REGION" ;;
        addon/*)      IFS=/ read -r _ CL ADDON _ <<< "$RES"; aws eks delete-addon --cluster-name "$CL" --addon-name "$ADDON" --region "$REGION" ;;
        *) warn "   ⚠️ Unhandled EKS resource $RES" ;;
      esac ;;
    s3)        aws s3 rb "s3://${RES#::}" --force ;;
    route53)   aws route53 delete-hosted-zone --id "${RES#hostedzone/}" ;;
    iam)
      case $RES in
        policy/*)            aws iam delete-policy --policy-arn "$ARN" ;;
        role/*)              aws iam delete-role --role-name "${RES#role/}" ;;
        instance-profile/*)  aws iam delete-instance-profile --instance-profile-name "${RES#instance-profile/}" ;;
        oidc-provider/*)     aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$ARN" ;;
        *) warn "   ⚠️ Unhandled IAM resource $RES" ;;
      esac ;;
    logs)      aws logs delete-log-group --log-group-name "${RES#log-group/}" --region "$REGION" ;;
    events)    aws events delete-rule --name "${RES#rule/}" --region "$REGION" --force ;;
    ecs)       aws ecs delete-cluster --cluster "${RES#cluster/}" --region "$REGION" ;;
    sqs)       aws sqs delete-queue --queue-url "https://sqs.${REGION}.amazonaws.com/${ACCOUNT_ID}/${RES#*/}" ;;
    codewhisperer) aws codewhisperer delete-profile --profile-id "${RES#profile/}" --region "$REGION" ;;
    *) warn "   ⚠️  Unhandled service $SVC";;
  esac
}

################ MAIN LOOP ################
cyan "🌎  Region: $REGION"

# skip if Tagging-API is blocked
if ! aws resourcegroupstaggingapi get-resources \
       --region "$REGION" --no-cli-pager \
       --query 'ResourceTagMappingList[0]' --output json >/dev/null 2>&1; then
  warn "⏭️  tag:GetResources denied in $REGION – aborting."
  exit 0
fi

TOKEN=""
while true; do
  RESP=$(aws resourcegroupstaggingapi get-resources \
           --region "$REGION" --output json \
           ${TOKEN:+--starting-token "$TOKEN"}) || true

  ARNS=$(echo "$RESP" | jq -r '.ResourceTagMappingList[].ResourceARN')
  [[ -z $ARNS ]] && break

  for ARN in $ARNS; do
    delete_arn "$ARN"
  done

  TOKEN=$(echo "$RESP" | jq -r '.PaginationToken')
  [[ -z $TOKEN || $TOKEN == "null" ]] && break
done
