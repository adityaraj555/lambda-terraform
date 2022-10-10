
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

module "step_function" {
  source = "git::https://github.eagleview.com/infrastructure/terraform-cloudops-module-step-function.git//step_function/?ref=2.0.0"
  providers = {
    aws = aws
  }
  for_each = module.config.step_function_config_map

  sfn_name             = each.key
  resource_name_prefix = local.resource_name_prefix
  source_path          = each.value.source_path
  sfn_def_env_vars     = each.value.sfn_def_env_vars
}

resource "aws_sqs_queue" "sqs" {

  for_each = module.config.sqs_config_map

  name                       = "${local.resource_name_prefix}-sqs-${each.key}"
  delay_seconds              = each.value.delay_seconds
  max_message_size           = each.value.max_message_size
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  policy                     = each.value.policy
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
}

// Name of the legacy order queue
resource "aws_lambda_event_source_mapping" "event_trigger_sqs" {
  event_source_arn = "arn:aws:sqs:${local.region}:${local.account_id}:${local.resource_name_prefix}-sqs-${module.config.environment_config_map.request_sqs_queue_name}"
  function_name    = "arn:aws:lambda:${local.region}:${local.resource_name_prefix}-lambda-${module.config.environment_config_map.evml_start_sfn}" //module.invokesfn_lambda[0].arn
  depends_on       = [module.lambda]
}


data "aws_caller_identity" "current" {}

// Useful to troubleshoot role issues
output "assumed-identity-arn" {
  value = data.aws_caller_identity.current.arn
}
