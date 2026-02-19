Feature: k3s cluster compute configuration
  As an infrastructure engineer
  I want k3s nodes properly configured for HA operation
  So that the cluster is reliable and cost-effective

  Scenario: k3s nodes must use gp3 volumes
    Given I have aws_instance defined
    Then it must contain root_block_device
    And it must contain volume_type
    And its value must be "gp3"

  Scenario: k3s nodes must have proper tags
    Given I have aws_instance defined
    Then it must contain tags
    And it must contain Environment

  Scenario: SSM parameter for k3s token must be encrypted
    Given I have aws_ssm_parameter defined
    Then it must contain type
    And its value must be "SecureString"

  Scenario: IAM role must have proper assume role policy
    Given I have aws_iam_role defined
    Then it must contain assume_role_policy
