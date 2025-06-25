variable "cluster_name"        {
     type = string 
     }
variable "cluster_endpoint"    {
     type = string 
     }
variable "oidc_provider_arn"   {
     type = string 
     }
variable "private_subnet_ids"  {
     type = list(string) 
     }
variable "helm_chart_version"  {
     type = string 
     default = "v0.38.2"
     }
variable "tags"                {
     type = map(string) 
     default = {} 
     }
