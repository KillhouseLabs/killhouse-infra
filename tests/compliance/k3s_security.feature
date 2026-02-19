Feature: k3s cluster security hardening
  As a security-conscious platform operator
  I want k3s nodes to follow security best practices
  So that the cluster is protected from common attack vectors

  Scenario: k3s nodes must use encrypted root volumes
    Given I have aws_instance defined
    Then it must contain root_block_device
    And it must contain encrypted

  Scenario: k3s nodes must enforce IMDSv2
    Given I have aws_instance defined
    Then it must contain metadata_options
    And it must contain http_tokens
    And its value must be "required"

  Scenario: k3s security group must not allow SSH from anywhere
    Given I have aws_security_group defined
    When it has ingress
    Then it must not have ingress with port 22 and cidr_blocks containing "0.0.0.0/0"

  Scenario: k3s security group must not allow all inbound traffic
    Given I have aws_security_group defined
    When it has ingress
    Then it must not have ingress with protocol "-1" and cidr_blocks containing "0.0.0.0/0"

  Scenario: k3s API server port must be restricted
    Given I have aws_security_group defined
    When it has ingress
    Then it must not have ingress with port 6443 and cidr_blocks containing "0.0.0.0/0"
