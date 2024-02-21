
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "appmesh:StreamAggregatedResources",
            "cloudwatch:PutMetricData",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries"            
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

# ECS task execution role

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

  inline_policy {
    name = "ecs_task_execution_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "s3:Get*",
            "s3:List*",
            "s3:Describe*",
            "ssm:GetParameters",
            "secretsmanager:GetSecretValue",
            "kms:Decrypt",
            "appmesh:StreamAggregatedResources"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}