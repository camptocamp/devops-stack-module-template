terraform {
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = ">= 4"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 1"
    }
  }
}
