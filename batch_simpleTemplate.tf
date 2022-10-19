module "batch" {
  source = "terraform-aws-modules/batch/aws"

  compute_environments = {
    a_ec2 = {
      name_prefix = "ec2"

      compute_resources = {
        type           = "EC2"
        min_vcpus      = 4
        max_vcpus      = 16
        desired_vcpus  = 4
        instance_types = ["m5.large", "r5.large"]

        security_group_ids = ["sg-f1d03a88"]
        subnets            = ["subnet-30ef7b3c", "subnet-1ecda77b", "subnet-ca09ddbc"]

        # Note - any tag changes here will force compute environment replacement
        # which can lead to job queue conflicts. Only specify tags that will be static
        # for the lifetime of the compute environment
        tags = {
          # This will set the name on the Ec2 instances launched by this compute environment
          Name = "example"
          Type = "Ec2"
        }
      }
    }

    b_ec2_spot = {
      name_prefix = "ec2_spot"

      compute_resources = {
        type                = "SPOT"
        allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"
        bid_percentage      = 20

        min_vcpus      = 4
        max_vcpus      = 16
        desired_vcpus  = 4
        instance_types = ["m4.large", "m3.large", "r4.large", "r3.large"]

        security_group_ids = ["sg-f1d03a88"]
        subnets            = ["subnet-30ef7b3c", "subnet-1ecda77b", "subnet-ca09ddbc"]

        # Note - any tag changes here will force compute environment replacement
        # which can lead to job queue conflicts. Only specify tags that will be static
        # for the lifetime of the compute environment
        tags = {
          # This will set the name on the Ec2 instances launched by this compute environment
          Name = "example-spot"
          Type = "Ec2Spot"
        }
      }
    }
  }

  # Job queus and scheduling policies
  job_queues = {
    low_priority = {
      name     = "LowPriorityEc2"
      state    = "ENABLED"
      priority = 1

      tags = {
        JobQueue = "Low priority job queue"
      }
    }

    high_priority = {
      name     = "HighPriorityEc2"
      state    = "ENABLED"
      priority = 99

      fair_share_policy = {
        compute_reservation = 1
        share_decay_seconds = 3600

        share_distribution = [{
          share_identifier = "A1*"
          weight_factor    = 0.1
          }, {
          share_identifier = "A2"
          weight_factor    = 0.2
        }]
      }

      tags = {
        JobQueue = "High priority job queue"
      }
    }
  }

  job_definitions = {
    example = {
      name           = "example"
      propagate_tags = true

      container_properties = jsonencode({
        command = ["ls", "-la"]
        image   = "public.ecr.aws/runecast/busybox:1.33.1"
        resourceRequirements = [
          { type = "VCPU", value = "1" },
          { type = "MEMORY", value = "1024" }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/aws/batch/example"
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "ec2"
          }
        }
      })

      attempt_duration_seconds = 60
      retry_strategy = {
        attempts = 3
        evaluate_on_exit = {
          retry_error = {
            action       = "RETRY"
            on_exit_code = 1
          }
          exit_success = {
            action       = "EXIT"
            on_exit_code = 0
          }
        }
      }

      tags = {
        JobDefinition = "Example"
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
