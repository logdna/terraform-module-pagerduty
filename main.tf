provider "pagerduty" {
  token = var.pagerduty_token
}

data "pagerduty_escalation_policy" "escalation_policy" {
  name = var.escalation_policy
}

data "pagerduty_ruleset" "default_global" {
  name = "Default Global"
}

resource "pagerduty_service" "cluster_environment" {
  name                    = var.cluster_name
  description             = "${var.cluster_name} - managed by Terraform"
  escalation_policy       = data.pagerduty_escalation_policy.escalation_policy.id
  alert_creation          = "create_alerts_and_incidents"
  auto_resolve_timeout    = "null"
  acknowledgement_timeout = "null"

  incident_urgency_rule {
    type    = "constant"
    urgency = "severity_based"
  }
}

resource "pagerduty_ruleset_rule" "environment_ruleset_rule" {
  ruleset = data.pagerduty_ruleset.default_global.id

  lifecycle {
    ignore_changes = [
      # We don't care about the position of the rule inside Pagerduty since our
      # rules should be written so that we get the correct result regardless of
      # the ordering inside the global default rule set.
      position
    ]
  }

  conditions {
    operator = "or"
    subconditions {
      operator = "contains"
      parameter {
        value = "kubernetes.cluster.name = '${var.cluster_name}'"
        path  = "details.Scope"
      }
    }
    subconditions {
      operator = "contains"
      parameter {
        value = "agent.tag.cluster = '${var.cluster_name}'"
        path  = "details.Scope"
      }
    }
    subconditions {
      operator = "contains"
      parameter {
        value = var.cluster_name
        path  = "details.Scope"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        value = var.cluster_name
        path  = "headers.subject"
      }
    }
  }

  actions {
    route {
      value = pagerduty_service.cluster_environment.id
    }
    extractions {
      target = "dedup_key"
      source = "description"
      regex  = "(.*)"
    }
    extractions {
      target = "summary"
      source = "details.Subject"
      regex  = "(.*)"
    }
  }
}

resource "pagerduty_service_event_rule" "critical_ruleset_rule" {
  service  = pagerduty_service.cluster_environment.id
  position = 0
  disabled = false
  conditions {
    operator = "or"
    subconditions {
      operator = "equals"
      parameter {
        value = "High"
        path  = "custom_details.Severity"
      }
    }
  }
  actions {
    severity {
      value = "critical"
    }
  }
  lifecycle {
    ignore_changes = [
      position,
    ]
  }
}

resource "pagerduty_service_event_rule" "warning_ruleset_rule" {
  service  = pagerduty_service.cluster_environment.id
  position = 1
  disabled = false
  conditions {
    operator = "or"
    subconditions {
      operator = "equals"
      parameter {
        value = "Medium"
        path  = "custom_details.Severity"
      }
    }
  }
  actions {
    severity {
      value = "warning"
    }
  }
  lifecycle {
    ignore_changes = [
      position,
    ]
  }
}

resource "pagerduty_service_event_rule" "info_ruleset_rule" {
  service  = pagerduty_service.cluster_environment.id
  position = 2
  disabled = false
  conditions {
    operator = "or"
    subconditions {
      operator = "equals"
      parameter {
        value = "Low"
        path  = "custom_details.Severity"
      }
    }
  }
  actions {
    severity {
      value = "info"
    }
  }
  lifecycle {
    ignore_changes = [
      position,
    ]
  }
}
