resource "shoreline_notebook" "kubernetes_statefulset_replicas_monitoring_incident" {
  name       = "kubernetes_statefulset_replicas_monitoring_incident"
  data       = file("${path.module}/data/kubernetes_statefulset_replicas_monitoring_incident.json")
  depends_on = [shoreline_action.invoke_statefulset_health_check,shoreline_action.invoke_kubectl_statefulset_network_check,shoreline_action.invoke_scale_up_statefulset]
}

resource "shoreline_file" "statefulset_health_check" {
  name             = "statefulset_health_check"
  input_file       = "${path.module}/data/statefulset_health_check.sh"
  md5              = filemd5("${path.module}/data/statefulset_health_check.sh")
  description      = "Resource constraints: Resource constraints such as CPU, memory, or disk space issues can cause the Kubernetes Statefulset replicas to stop functioning. This can lead to the triggering of the incident mentioned above."
  destination_path = "/agent/scripts/statefulset_health_check.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "kubectl_statefulset_network_check" {
  name             = "kubectl_statefulset_network_check"
  input_file       = "${path.module}/data/kubectl_statefulset_network_check.sh"
  md5              = filemd5("${path.module}/data/kubectl_statefulset_network_check.sh")
  description      = "Network issues: Network issues such as DNS resolution failure, network connectivity issues, or firewall configuration errors can cause the Kubernetes Statefulset replicas to stop functioning. As a result, this could trigger the incident mentioned above."
  destination_path = "/agent/scripts/kubectl_statefulset_network_check.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "scale_up_statefulset" {
  name             = "scale_up_statefulset"
  input_file       = "${path.module}/data/scale_up_statefulset.sh"
  md5              = filemd5("${path.module}/data/scale_up_statefulset.sh")
  description      = "Scale up the number of replicas to ensure that the desired state is achieved and the workload is available."
  destination_path = "/agent/scripts/scale_up_statefulset.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_statefulset_health_check" {
  name        = "invoke_statefulset_health_check"
  description = "Resource constraints: Resource constraints such as CPU, memory, or disk space issues can cause the Kubernetes Statefulset replicas to stop functioning. This can lead to the triggering of the incident mentioned above."
  command     = "`chmod +x /agent/scripts/statefulset_health_check.sh && /agent/scripts/statefulset_health_check.sh`"
  params      = ["MEMORY_THRESHOLD_IN_BYTES","KUBE_STATEFUL_SET","CPU_THRESHOLD_IN_MILLICORES","DISK_THRESHOLD_IN_PERCENT"]
  file_deps   = ["statefulset_health_check"]
  enabled     = true
  depends_on  = [shoreline_file.statefulset_health_check]
}

resource "shoreline_action" "invoke_kubectl_statefulset_network_check" {
  name        = "invoke_kubectl_statefulset_network_check"
  description = "Network issues: Network issues such as DNS resolution failure, network connectivity issues, or firewall configuration errors can cause the Kubernetes Statefulset replicas to stop functioning. As a result, this could trigger the incident mentioned above."
  command     = "`chmod +x /agent/scripts/kubectl_statefulset_network_check.sh && /agent/scripts/kubectl_statefulset_network_check.sh`"
  params      = ["POD_NAME","SERVICE"]
  file_deps   = ["kubectl_statefulset_network_check"]
  enabled     = true
  depends_on  = [shoreline_file.kubectl_statefulset_network_check]
}

resource "shoreline_action" "invoke_scale_up_statefulset" {
  name        = "invoke_scale_up_statefulset"
  description = "Scale up the number of replicas to ensure that the desired state is achieved and the workload is available."
  command     = "`chmod +x /agent/scripts/scale_up_statefulset.sh && /agent/scripts/scale_up_statefulset.sh`"
  params      = []
  file_deps   = ["scale_up_statefulset"]
  enabled     = true
  depends_on  = [shoreline_file.scale_up_statefulset]
}

