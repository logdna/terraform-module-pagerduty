Terraforming Pagerduty example module
=====================================

This Terraform module set's up routing of incoming events using Sysdig and
Email to a cluster (service in Pagerduty terminology). It uses both event rules
both on the global level and on the service level. It has been extracted from
an internal Terraform module used by LogDNA to configure our Pagerduty setup.
