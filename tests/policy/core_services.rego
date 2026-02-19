package main

import future.keywords.in

# Core services must be in killhouse-system namespace
deny[msg] {
  input.kind in ["Deployment", "Service"]
  input.metadata.namespace == "killhouse-system"
  not input.metadata.labels["app.kubernetes.io/part-of"]
  msg := sprintf("%s '%s' must have 'app.kubernetes.io/part-of' label", [input.kind, input.metadata.name])
}

# Scanner-api and sandbox must NOT mount docker.sock
deny[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-system"
  volume := input.spec.template.spec.volumes[_]
  volume.hostPath.path == "/var/run/docker.sock"
  msg := sprintf("deployment '%s' must not mount docker.sock - use K8s API instead", [input.metadata.name])
}

# All core services must have anti-affinity or topology spread
warn[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-system"
  input.spec.replicas > 1
  not input.spec.template.spec.topologySpreadConstraints
  not input.spec.template.spec.affinity
  msg := sprintf("deployment '%s' with >1 replicas should have topology spread or anti-affinity", [input.metadata.name])
}

# Core services must have security context
deny[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-system"
  container := input.spec.template.spec.containers[_]
  not container.securityContext
  msg := sprintf("container '%s' in '%s' must have securityContext", [container.name, input.metadata.name])
}

# Containers must not run as root
deny[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-system"
  container := input.spec.template.spec.containers[_]
  container.securityContext.runAsUser == 0
  msg := sprintf("container '%s' in '%s' must not run as root", [container.name, input.metadata.name])
}

# All Deployments must have readiness probes
deny[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-system"
  container := input.spec.template.spec.containers[_]
  not container.readinessProbe
  msg := sprintf("container '%s' in '%s' must have readinessProbe", [container.name, input.metadata.name])
}
