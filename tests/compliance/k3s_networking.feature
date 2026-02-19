Feature: k3s cluster networking
  As an infrastructure engineer
  I want k3s nodes deployed in private subnets behind NLB
  So that nodes are not directly exposed to the internet

  Scenario: k3s nodes must not have public IP mapping
    Given I have aws_instance defined
    Then it must not contain associate_public_ip_address

  Scenario: NLB must be internet-facing for API access
    Given I have aws_lb defined
    Then it must contain internal
    And its value must be false

  Scenario: NLB must use network type
    Given I have aws_lb defined
    Then it must contain load_balancer_type
    And its value must be "network"

  Scenario: NLB target group must health check on port 6443
    Given I have aws_lb_target_group defined
    Then it must contain port
    And its value must be 6443
