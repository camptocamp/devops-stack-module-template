terraform {
  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = ">= 6"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3"
    }
  }
}
