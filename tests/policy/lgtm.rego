package main

import future.keywords.in

# LGTM stack must be deployed in dedicated namespace
deny[msg] {
  input.kind == "Namespace"
  input.metadata.name == "killhouse-monitoring"
  not input.metadata.labels["app.kubernetes.io/part-of"]
  msg := "monitoring namespace must have 'app.kubernetes.io/part-of' label"
}

# All LGTM deployments must have resource limits
deny[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-monitoring"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := sprintf("container '%s' in deployment '%s' must have resource limits", [container.name, input.metadata.name])
}

# All LGTM deployments must have resource requests
deny[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-monitoring"
  container := input.spec.template.spec.containers[_]
  not container.resources.requests
  msg := sprintf("container '%s' in deployment '%s' must have resource requests", [container.name, input.metadata.name])
}

# Grafana must not run as root
deny[msg] {
  input.kind == "Deployment"
  input.metadata.name == "grafana"
  container := input.spec.template.spec.containers[_]
  container.securityContext.runAsUser == 0
  msg := "Grafana must not run as root (runAsUser: 0)"
}

# All StatefulSets must have PVC templates
deny[msg] {
  input.kind == "StatefulSet"
  input.metadata.namespace == "killhouse-monitoring"
  not input.spec.volumeClaimTemplates
  msg := sprintf("StatefulSet '%s' must have volumeClaimTemplates for persistent storage", [input.metadata.name])
}

# Services must not use NodePort in production
deny[msg] {
  input.kind == "Service"
  input.metadata.namespace == "killhouse-monitoring"
  input.spec.type == "NodePort"
  msg := sprintf("Service '%s' must not use NodePort type", [input.metadata.name])
}

# All pods must have liveness and readiness probes
warn[msg] {
  input.kind == "Deployment"
  input.metadata.namespace == "killhouse-monitoring"
  container := input.spec.template.spec.containers[_]
  not container.readinessProbe
  msg := sprintf("container '%s' in '%s' should have a readinessProbe", [container.name, input.metadata.name])
}
