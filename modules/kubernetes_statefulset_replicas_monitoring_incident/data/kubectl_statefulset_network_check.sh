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