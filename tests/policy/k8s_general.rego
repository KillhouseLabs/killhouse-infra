package main

import future.keywords.in

# All resources must have standard labels
deny[msg] {
  required_labels := {"app.kubernetes.io/name", "app.kubernetes.io/part-of"}
  input.kind in ["Deployment", "StatefulSet", "DaemonSet"]
  label := required_labels[_]
  not input.metadata.labels[label]
  msg := sprintf("%s '%s' must have label '%s'", [input.kind, input.metadata.name, label])
}

# Containers must not use latest tag
deny[msg] {
  input.kind in ["Deployment", "StatefulSet", "DaemonSet"]
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("container '%s' must not use ':latest' image tag", [container.name])
}

# Containers must set CPU and memory limits
deny[msg] {
  input.kind in ["Deployment", "StatefulSet", "DaemonSet"]
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("container '%s' in '%s' must have memory limit", [container.name, input.metadata.name])
}
