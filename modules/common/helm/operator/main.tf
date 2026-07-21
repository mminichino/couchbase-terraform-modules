##

resource "helm_release" "couchbase_operator" {
  name             = "couchbase"
  namespace        = var.namespace
  repository       = "https://couchbase-partners.github.io/helm-charts/"
  chart            = "couchbase-operator"
  version          = var.operator_version
  create_namespace = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      install = {
        couchbaseOperator = true
        admissionController = true
        couchbaseCluster = false
        syncGateway = false
      }
    })
  ]
}
