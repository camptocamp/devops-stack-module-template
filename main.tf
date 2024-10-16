resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "argocd_project" "this" {
  count = var.argocd_project == null ? 1 : 0

  metadata {
    name      = var.destination_cluster != "in-cluster" ? "<CHART_NAME>-${var.destination_cluster}" : "<CHART_NAME>"
    namespace = "argocd"
  }

  spec {
    description  = "<CHART_NAME> application project for cluster ${var.destination_cluster}"
    source_repos = ["https://github.com/camptocamp/devops-stack-module-<CHART_NAME>.git"]

    destination {
      name      = var.destination_cluster
      namespace = "<CHART_NAME>"
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

data "utils_deep_merge_yaml" "values" {
  input       = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
  append_list = var.deep_merge_append_list
}

resource "argocd_application" "this" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "<CHART_NAME>-${var.destination_cluster}" : "<CHART_NAME>"
    namespace = "argocd"
    labels = merge({
      "application" = "<CHART_NAME>"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = "https://github.com/camptocamp/devops-stack-module-<CHART_NAME>.git"
      path            = "charts/<CHART_NAME>"
      target_revision = var.target_revision
      helm {
        release_name = "<CHART_NAME>"
        values       = data.utils_deep_merge_yaml.values.output
      }
    }

    destination {
      name      = var.destination_cluster
      namespace = "<CHART_NAME>"
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
