package main

import future.keywords.in

# Sandbox namespaces must have isolation NetworkPolicy
deny[msg] {
  input.kind == "NetworkPolicy"
  startswith(input.metadata.namespace, "sandbox-")
  input.metadata.name == "sandbox-isolation"
  not input.spec.policyTypes
  msg := "sandbox NetworkPolicy must specify policyTypes"
}

# Sandbox target pods must use gVisor RuntimeClass
deny[msg] {
  input.kind == "Pod"
  startswith(input.metadata.namespace, "sandbox-")
  input.metadata.labels["killhouse.io/component"] == "target"
  not input.spec.runtimeClassName
  msg := sprintf("sandbox target pod '%s' must have runtimeClassName set", [input.metadata.name])
}

deny[msg] {
  input.kind == "Pod"
  startswith(input.metadata.namespace, "sandbox-")
  input.metadata.labels["killhouse.io/component"] == "target"
  input.spec.runtimeClassName != "gvisor"
  msg := sprintf("sandbox target pod '%s' must use 'gvisor' RuntimeClass, got '%s'", [input.metadata.name, input.spec.runtimeClassName])
}

# Sandbox pods must not have privilege escalation
deny[msg] {
  input.kind == "Pod"
  startswith(input.metadata.namespace, "sandbox-")
  container := input.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("sandbox container '%s' must not be privileged", [container.name])
}

# Sandbox ResourceQuota must exist
deny[msg] {
  input.kind == "ResourceQuota"
  startswith(input.metadata.namespace, "sandbox-")
  not input.spec.hard["limits.cpu"]
  msg := "sandbox ResourceQuota must define limits.cpu"
}

deny[msg] {
  input.kind == "ResourceQuota"
  startswith(input.metadata.namespace, "sandbox-")
  not input.spec.hard["limits.memory"]
  msg := "sandbox ResourceQuota must define limits.memory"
}

# BuildKit must run rootless
deny[msg] {
  input.kind == "StatefulSet"
  input.metadata.name == "buildkitd"
  container := input.spec.template.spec.containers[_]
  container.securityContext.runAsUser == 0
  msg := "BuildKit must not run as root"
}

# BuildKit must have persistent volume for cache
deny[msg] {
  input.kind == "StatefulSet"
  input.metadata.name == "buildkitd"
  not input.spec.volumeClaimTemplates
  msg := "BuildKit StatefulSet must have volumeClaimTemplates for build cache"
}
