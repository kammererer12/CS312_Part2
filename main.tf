terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  region                   = "us-west-2"
  shared_credentials_files = [".\\.aws\\credentials"]
}


resource "aws_ecs_cluster" "minecraft_ecs_cluster" {
  name = "minecraft-ecs"
}

resource "aws_ecs_task_definition" "minecraft_task" {
  family                   = "minecraft-task"
  container_definitions    = jsonencode([
      {
          "name": "minecraft-task",
          "image": "itzg/minecraft-server",
          "essential": true,
          "portMappings": [
              {
                  "containerPort": 25565,
                  "hostPort": 25565
              }
          ],
          "environment": [
              {
                  "name": "EULA",
                  "value": "TRUE"
              }
          ],
          "memory": 1024,
          "cpu": 512
      }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 1024 
  cpu                      = 512 
}


resource "aws_vpc" "minecraft_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id
}

resource "aws_subnet" "subnet_a" {
  vpc_id = aws_vpc.minecraft_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id = aws_vpc.minecraft_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_route_table" "minecraft_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id
}

resource "aws_route" "minecraft_route" {
  route_table_id = aws_route_table.minecraft_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.minecraft_igw.id
}

resource "aws_route_table_association" "subnet_a_association" {
  subnet_id = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.minecraft_rt.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.minecraft_rt.id
}


resource "aws_lb" "load_balancer" {
  name               = "load-balancer"
  load_balancer_type = "network"
  subnets = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]

  security_groups = [aws_security_group.lb_security_group.id]
}

resource "aws_security_group" "lb_security_group" {
  vpc_id = aws_vpc.minecraft_vpc.id
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "minecraft_security_group" {
  vpc_id = aws_vpc.minecraft_vpc.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "minecraft_target" {
  name        = "minecraft-target-group"
  port        = 25565
  protocol = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.minecraft_vpc.id
}

resource "aws_lb_listener" "minecraft_listener" {
    load_balancer_arn = aws_lb.load_balancer.arn
    port = "25565"
    protocol = "TCP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.minecraft_target.arn
    }
}

resource "aws_ecs_service" "minecraft_service" {
  name            = "minecraft-service"
  cluster         = aws_ecs_cluster.minecraft_ecs_cluster.id
  task_definition = aws_ecs_task_definition.minecraft_task.arn
  launch_type     = "FARGATE"
  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.minecraft_target.arn
    container_name   = aws_ecs_task_definition.minecraft_task.family
    container_port   = 25565
  }

  network_configuration {
    subnets          = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.minecraft_security_group.id]
  }
}

output "server_url" {
  value = aws_lb.load_balancer.dns_name
}
