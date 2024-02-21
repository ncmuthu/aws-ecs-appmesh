##
# ECS Cluster
##

# Cloudwatch log group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${var.env}-ecs-logs"
}

resource "aws_cloudwatch_log_group" "task_log_group" {
  name = "${var.env}-task-logs"
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.env}-cluster01"

  setting {
    name  = "containerInsights"
    value = "disabled"
  } 
  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_log_group.name
      }
    }
  }
}

##
# ECS Container and Task definition
##

# Container definition from file
data "template_file" "container_definitions" {
    template = file("./container_definitions.tpl")

    vars = {
        env    = var.env,
        region = var.region,
        container01_image_name = var.container01_image_name,
        container02_image_name = var.container02_image_name
    }
}

data "template_file" "container_definitions_02" {
    template = file("./container_definitions_02.tpl")

    vars = {
        env    = var.env,
        region = var.region,
        container01_image_name = var.container01_image_name,
        container02_image_name = var.container02_image_name
    }
}

# Task definition
resource "aws_ecs_task_definition" "task_def" {
  family                    = "${var.env}-task01"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = 1024
  memory                    = 2048
  task_role_arn             = aws_iam_role.ecs_task_role.arn
  execution_role_arn        = "${aws_iam_role.ecs_task_execution_role.arn}"
  container_definitions     = "${data.template_file.container_definitions.rendered}"
  ephemeral_storage {
    size_in_gib             = 22
  }
  volume {
    name                    = "myebsvol02"
  }
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"    
  }
  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = "5432"
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = "15001"
      ProxyIngressPort = "15000"
    }
  }
}

resource "aws_ecs_task_definition" "task_def_02" {
  family                    = "${var.env}-task02"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = 1024
  memory                    = 2048
  task_role_arn             = aws_iam_role.ecs_task_role.arn
  execution_role_arn        = "${aws_iam_role.ecs_task_execution_role.arn}"
  container_definitions     = "${data.template_file.container_definitions_02.rendered}"
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"    
  }
  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = "80"
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = "15001"
      ProxyIngressPort = "15000"
    }
  }
}

##
# ECS Service
##

# ECS service
resource "aws_ecs_service" "ecs_service" {
  name             = "${var.env}-service-01"
  cluster          = aws_ecs_cluster.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.task_def.arn
  desired_count    = 0
  launch_type      = "FARGATE"
  # Optional: Allow external changes without Terraform plan difference
  #lifecycle {
  #  ignore_changes = [desired_count]
  #}
  service_registries {
    registry_arn   = aws_service_discovery_service.discovery_service.arn
    container_name = "postgres"
  }  
  network_configuration {
    subnets          = [ aws_subnet.subnet03.id ]
    assign_public_ip = true
  }
  enable_execute_command = true  
}

resource "aws_ecs_service" "ecs_service_02" {
  name             = "${var.env}-nginx"
  cluster          = aws_ecs_cluster.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.task_def_02.arn
  desired_count    = 0
  launch_type      = "FARGATE"
  # Optional: Allow external changes without Terraform plan difference
  #lifecycle {
  #  ignore_changes = [desired_count]
  #}
  service_registries {
    registry_arn   = aws_service_discovery_service.discovery_service_nginx.arn
    container_name = "nginx"
  }  
  network_configuration {
    subnets          = [ aws_subnet.subnet03.id ]
    assign_public_ip = true
  }
  enable_execute_command = true  
}

# Image repository

resource "aws_ecr_repository" "ecr" {
  name                 = "myecr01/nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

##
# Service discovery
##

resource "aws_service_discovery_private_dns_namespace" "dev_namespace" {
  name        = "${var.env}-cluster01"
  vpc         = aws_vpc.vpc.id
}

resource "aws_service_discovery_service" "discovery_service" {
  name = "postgres"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dev_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "discovery_service_nginx" {
  name = "nginx"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dev_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}