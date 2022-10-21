
module "config" {
  source = "git::https://github.eagleview.com/engineering/evml-building-detection-terraform-config.git//${platform_choice}${test_config_branch}"
}

module "lambda" {
  source = "git::https://github.eagleview.com/infrastructure/terraform-cloudops-module-lambda.git//lambda?ref=3.2.0"

  providers = {
    aws = aws
  }

  for_each = module.config.lambda_configmap

  resource_name_prefix      = local.resource_name_prefix
  image_uri                 = each.value.image_uri
  package_type              = try(each.value.package_type, "Image")
  vpc_id                    = each.value.vpc_id
  environment_variables     = try(each.value.environment_variables, null)
  lambda_name               = each.key
  lambda_handler            = each.value.lambda_handler
  lambda_description        = each.value.lambda_description
  managed_policy_arns       = each.value.managed_policy_arns
  lambda_inline_policy      = try(each.value.lambda_inline_policy, null)
  schedule_time_trigger     = try(each.value.schedule_time_trigger, null)
  aws_lambda_permission     = try(each.value.aws_lambda_permission, [])
  lambda_assume_role_policy = try(each.value.lambda_assume_role_policy, null)
  timeout                   = try(each.value.timeout, 3)
  memory_size               = try(each.value.memory_size, 128)
  source_path               = null
}

module "batch" {
  source = "git::https://github.eagleview.com/infrastructure/terraform-cloudops-module-aws-batch.git//batch/?ref=CL-93"

  for_each = module.config.batch_configmap

  resource_name_prefix     = local.resource_name_prefix
  batch_name               = each.key
  container_properties     = each.value.container_properties
  compute_environments     = each.value.compute_environments
}


data "aws_caller_identity" "current" {}

// Useful to troubleshoot role issues
output "assumed-identity-arn" {
  value = data.aws_caller_identity.current.arn
}
