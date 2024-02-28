# TODO: insert resources here.
data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_TODO_the_resource_for_this_module" "this" {
  name                = var.name # calling code must supply the name
  resource_group_name = var.resource_group_name
  location            = coalesce(var.location, local.resource_group_location)
  # etc
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_TODO_resource.this.id
  lock_level = var.lock.kind
}

resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_TODO_resource.this.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

resource "azurerm_data_factory" "this" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  public_network_enabled           = var.public_network_enabled
  customer_managed_key_id          = var.customer_managed_key_id
  customer_managed_key_identity_id = var.customer_managed_key_identity_id

  # Supported only in azurerm provider version 2.68.0
  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  dynamic "identity" {
    for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? { this = var.managed_identities } : {}
    content {
      type = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  dynamic "global_parameter" {
    for_each = var.global_parameters
    content {
      name  = global_parameter.value.name
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }

  # Dynamic block for configuring github configuration;
  # dynamic "github_configuration" {
  #   for_each = [for v in [var.github_configuration] : v if length(v) > 0]
  #   content {
  #     account_name    = lookup(github_configuration.value, "account_name", null)
  #     branch_name     = lookup(github_configuration.value, "branch_name", null)
  #     git_url         = lookup(github_configuration.value, "git_url", null)
  #     repository_name = lookup(github_configuration.value, "repository_name", null)
  #     root_folder     = lookup(github_configuration.value, "root_folder", null)
  #   }
  # }

  # # Dynamic block for configuring vsts_configuration configuration;
  # dynamic "vsts_configuration" {
  #   for_each = [for v in [var.vsts_configuration] : v if length(v) > 0]
  #   content {
  #     account_name    = lookup(vsts_configuration.value, "account_name", null)
  #     branch_name     = lookup(vsts_configuration.value, "branch_name", null)
  #     project_name    = lookup(vsts_configuration.value, "project_name", null)
  #     repository_name = lookup(vsts_configuration.value, "repository_name", null)
  #     root_folder     = lookup(vsts_configuration.value, "root_folder", null)
  #     tenant_id       = lookup(vsts_configuration.value, "tenant_id", data.azurerm_client_config.current.tenant_id)
  #   }
  # }
  tags = module.common_resource_tags.tags
}