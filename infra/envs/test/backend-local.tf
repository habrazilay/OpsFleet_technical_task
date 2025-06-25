terraform {
  # Store state file inside the repo (not recommended for shared use)
  backend "local" {
    # relative path so each env keeps its own state artefact
    path = "state/terraform-test.tfstate"
  }
}
