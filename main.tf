###########
# pre-reqs
# terraform login
# export TERRAFORM_CONFIG=$HOME/.terraform.d/credentials.tfrc.json"
##########

locals {
  delimiter        = "-"
  org_prefix       = "aws-quickstart"
  random_workspace = "${local.org_prefix}${local.delimiter}${random_string.rand4.result}"
  random_org       = "${local.org_prefix}${local.delimiter}${random_pet.name.id}"
}

resource "random_pet" "name" {
  length = 1
}

resource "random_string" "rand4" {
  length  = 4
  special = false
  upper   = false
}

resource "tfe_organization" "qs-org" {
  name  = var.tfe_organization == "" ? local.random_org : var.tfe_organization
  email = var.tfe_email == "" ? "someone@mycompany.com" : var.tfe_email
  count = var.tfe_organization != "" ? 0 : 1
}

resource "tfe_workspace" "qs-workspace" {
  depends_on   = [tfe_organization.qs-org]
  name         = var.tfe_workspace == "" ? local.random_workspace : var.tfe_workspace
  organization = var.tfe_organization != "" ? var.tfe_organization : tfe_organization.qs-org[0].name
}

resource "tfe_variable" "AWS_SECRET_ACCESS_KEY" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = var.AWS_SECRET_ACCESS_KEY
  sensitive    = true
  category     = "env"
  workspace_id = tfe_workspace.qs-workspace.id
  description  = "AWS_SECRET_ACCESS_KEY"
}

resource "tfe_variable" "AWS_ACCESS_KEY_ID" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = var.AWS_ACCESS_KEY_ID
  category     = "env"
  workspace_id = tfe_workspace.qs-workspace.id
  description  = "AWS_ACCESS_KEY_ID"
}

resource "null_resource" "backend_file" {
  depends_on = [tfe_workspace.qs-workspace]
  provisioner "local-exec" {
    command = "echo  workspaces '{' name = \\\"${tfe_workspace.qs-workspace.name}\\\" '}' > backend.hcl"
  }
  provisioner "local-exec" {
    command = "echo hostname = \\\"app.terraform.io\\\" >> backend.hcl"
  }
  provisioner "local-exec" {
    command = "echo  organization = \\\"${tfe_workspace.qs-workspace.organization}\\\" >> backend.hcl"
  }
}