variable "env" {
    type = string
}

variable "vpc_cidr" {
    type = string
    description = "VPC CIDR"
}

variable "region" {
    type = string
    description = "Cloud resources are created in which region"
}

variable "container01_image_name" {
    type = string
    description = "Image name of container 01"
}

variable "container02_image_name" {
    type = string
    description = "Image name of container 02"
}