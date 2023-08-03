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