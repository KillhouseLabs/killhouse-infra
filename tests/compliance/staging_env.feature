Feature: staging environment isolation
  As a platform operator
  I want the staging environment completely isolated from production
  So that testing never affects the live system

  Scenario: Staging VPC must use isolated CIDR
    Given I have aws_vpc defined
    Then it must contain cidr_block
    And its value must be "10.1.0.0/16"

  Scenario: VPC must have DNS support enabled
    Given I have aws_vpc defined
    Then it must contain enable_dns_support

  Scenario: VPC must have DNS hostnames enabled
    Given I have aws_vpc defined
    Then it must contain enable_dns_hostnames
