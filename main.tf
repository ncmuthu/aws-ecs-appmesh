/*
# Cloudwatch log group
resource "aws_cloudwatch_log_group" "cloudwatch" {
  name = "dev-cloudwatch"
}
*/

/*
# ECS Cluster

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "dev-cluster01"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }  
/*  
  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.cloudwatch.name
      }
    }
  }   
}
*/
