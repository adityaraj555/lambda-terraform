locals {
  test_build           = var.build_number != ""
  resource_name_prefix = local.test_build ? "tb-${var.build_number}-simple-terraform-1x0" : module.config.environment_config_map.resource_name_prefix
  region               = module.config.environment_config_map.region
  account_id           = module.config.environment_config_map.account_id
  default_provider_tags = {
    "evtech:environment"    = module.config.environment_config_map.environment
    "evtech:owner"          = module.config.environment_config_map.evtech_owner
    "evtech:program"        = module.config.environment_config_map.evtech_program
    "evtech:provisioned-by" = module.config.environment_config_map.evtech_owner
    "evtech:longterm"       = "30"
    "evtech:commit-hash"    = var.commit_hash
    "evtech:test-build"     = local.test_build
  }
}
