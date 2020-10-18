provider "aws" {
  region = "ap-south-1"
}
resource "aws_security_group" "mysql-rds" {
name        = "RDS-Security-Group"
  description = "MySQL Ports"
 
  ingress {
    description = "Mysql RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "Mysql-RDS"
  }
}
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "user1"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = true
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.mysql-rds.id]
  tags = {
  name = "RDS"
   }
}
provider "kubernetes" {
  config_context_cluster   = "minikube"
}
resource "kubernetes_deployment" "wp" {
  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }
spec {
    replicas = 1
selector {
      match_labels = {
        app = "wordpress"
      }
    }
template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }
spec {
        container {
          image = "wordpress"
          name  = "wp"
        }
      }
    }
  }
}
resource "kubernetes_service" "wp-expose"{
  depends_on = [kubernetes_deployment.wp]
  metadata {
    name = "wp-expose"
  }
  spec {
    selector = {
      app = kubernetes_deployment.wp.metadata.0.labels.app
    }
    port {
      node_port = 30001
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}