
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