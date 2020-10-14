variable "ENV" {
  default = "DEV"
}

variable "PROJECT" {
  description = "Name of the project"
  default = "vfie-poc"
}

variable "REGION" {
  default = "eu-west-1"
}

variable "api_gw_resources_and_methods" {
  type        = any

}