
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Kubernetes Statefulset Replicas Monitoring Incident
---

This incident type involves monitoring the replicas of a Kubernetes Statefulset, which is a type of workload in Kubernetes used for stateful applications. The incident is triggered when more than one replica's pods are down, creating an unsafe situation for manual operations. This incident is critical and requires immediate attention to resolve the issue and ensure the smooth functioning of the stateful applications.

### Parameters
```shell
# Environment Variables
export KUBE_STATEFUL_SET="PLACEHOLDER"
export KUBE_NAMESPACE="PLACEHOLDER"
export POD_NAME="PLACEHOLDER"
export CPU_THRESHOLD_IN_MILLICORES="PLACEHOLDER"
export DISK_THRESHOLD_IN_PERCENT="PLACEHOLDER"
export MEMORY_THRESHOLD_IN_BYTES="PLACEHOLDER"
export SERVICE="PLACEHOLDER"

```

## Debug

### Get the desired number of replicas for the specified Statefulset
```shell
kubectl get statefulset ${KUBE_STATEFUL_SET} -n ${KUBE_NAMESPACE} -o=jsonpath='{.spec.replicas}'
```

### Get the number of ready replicas for the specified Statefulset
```shell
kubectl get statefulset ${KUBE_STATEFUL_SET} -n ${KUBE_NAMESPACE} -o=jsonpath='{.status.readyReplicas}'
```

### Get the number of currently running replicas for the specified Statefulset
```shell
kubectl get statefulset ${KUBE_STATEFUL_SET} -n ${KUBE_NAMESPACE} -o=jsonpath='{.status.currentReplicas}'
```

### Get the number of replicas that are currently unavailable for the specified Statefulset
```shell
kubectl get statefulset ${KUBE_STATEFUL_SET} -n ${KUBE_NAMESPACE} -o=jsonpath='{.status.unavailableReplicas}'
```

### Get the status of all the pods belonging to the specified Statefulset
```shell
kubectl get pods -n ${KUBE_NAMESPACE} -l app=${KUBE_STATEFUL_SET} -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase
```

### Get the logs of the specified pod
```shell
kubectl logs ${POD_NAME} -n ${KUBE_NAMESPACE}
```

### Resource constraints: Resource constraints such as CPU, memory, or disk space issues can cause the Kubernetes Statefulset replicas to stop functioning. This can lead to the triggering of the incident mentioned above.
```shell
bash
#!/bin/bash

# Kubernetes Statefulset name
statefulset_name=${KUBE_STATEFUL_SET}

# Namespace where the Statefulset is deployed
namespace=${NAMESPACE}

# Check CPU usage of Statefulset replicas
cpu=$(kubectl top pods -n $namespace | grep $statefulset_name | awk '{total += $2} END {print total}')
cpu_threshold=${CPU_THRESHOLD_IN_MILLICORES}

if (( $cpu > $cpu_threshold )); then
  echo "CPU usage of $cpu millicores is higher than threshold of $cpu_threshold millicores."
  echo "Resource constraints may be causing the Statefulset replicas to stop functioning."
fi

# Check memory usage of Statefulset replicas
memory=$(kubectl top pods -n $namespace | grep $statefulset_name | awk '{total += $3} END {print total}')
memory_threshold=${MEMORY_THRESHOLD_IN_BYTES}

if (( $memory > $memory_threshold )); then
  echo "Memory usage of $memory bytes is higher than threshold of $memory_threshold bytes."
  echo "Resource constraints may be causing the Statefulset replicas to stop functioning."
fi

# Check disk usage of Statefulset replicas
disk=$(kubectl exec $statefulset_name-0 -n $namespace -- df --output=pcent /data | tail -1 | tr -dc '0-9')
disk_threshold=${DISK_THRESHOLD_IN_PERCENT}

if (( $disk > $disk_threshold )); then
  echo "Disk usage of $disk% is higher than threshold of $disk_threshold%."
  echo "Resource constraints may be causing the Statefulset replicas to stop functioning."
fi

```

### Network issues: Network issues such as DNS resolution failure, network connectivity issues, or firewall configuration errors can cause the Kubernetes Statefulset replicas to stop functioning. As a result, this could trigger the incident mentioned above.
```shell
bash
#!/bin/bash

# Set variables
CLUSTER_NAME=${CLUSTER_NAME}
NAMESPACE=${NAMESPACE}
STATEFULSET=${STATEFULSET}
SERVICE=${SERVICE}

# Check if the service is running
SERVICE_STATUS=$(kubectl get service $SERVICE -n $NAMESPACE | awk 'FNR == 2 {print $3}')
if [[ $SERVICE_STATUS != "Running" ]]; then
  echo "Service $SERVICE in namespace $NAMESPACE is not running. Exiting..."
  exit 1
fi

# Check if all the replicas are running
EXPECTED_REPLICAS=$(kubectl get statefulset $STATEFULSET -n $NAMESPACE | awk 'FNR == 2 {print $2}')
READY_REPLICAS=$(kubectl get statefulset $STATEFULSET -n $NAMESPACE | awk 'FNR == 2 {print $Ready}')
if [[ $EXPECTED_REPLICAS -ne $READY_REPLICAS ]]; then
  echo "Expected $EXPECTED_REPLICAS replicas of statefulset $STATEFULSET in namespace $NAMESPACE. But only $READY_REPLICAS are ready. Exiting..."
  exit 1
fi

# Check network connectivity
POD_NAMES=$(kubectl get pods -l app=$STATEFULSET -n $NAMESPACE | awk 'FNR > 1 {print $1}')
for POD_NAME in $POD_NAMES; do
  POD_IP=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.podIP}')
  if [[ $(curl --write-out %{http_code} --silent --output /dev/null $POD_IP) != 200 ]]; then
    echo "Network connectivity issue with pod $POD_NAME in namespace $NAMESPACE. Exiting..."
    exit 1
  fi
done

echo "No network issues found with Kubernetes Statefulset $STATEFULSET in namespace $NAMESPACE."

```
## Repair
---
### Scale up the number of replicas to ensure that the desired state is achieved and the workload is available.
```shell

#!/bin/bash

# Define variables
STATEFULSET_NAME=${NAME_OF_DEPLOYMENT}
NEW_REPLICAS="PLACEHOLDER"

# Scale up the deployment to the desired number of replicas
kubectl scale sts $STATEFULSET_NAME --replicas=$NEW_REPLICAS

# Check the status of the deployment
DEPLOYMENT_STATUS=$(kubectl get sts $STATEFULSET_NAME -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')

# Check if the deployment is available
if [ $STATEFULSET_NAME == "True" ]
then
  echo "$STATEFULSET_NAME is available."
else
  echo "$STATEFULSET_NAME is not available."
fi

```