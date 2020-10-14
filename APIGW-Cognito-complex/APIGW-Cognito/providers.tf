#default
provider "aws" {
  profile = "vf-iedelivery-sandbox-01"
  region = "eu-west-1"
  #assume_role {
  #  role_arn = 
  #}
}

provider "aws" {
  alias  = "use1"
  profile = "vf-iedelivery-sandbox-01"
  region = "us-east-1"
  
  #assume_role {
  #  role_arn = "arn:aws:iam::299879056526:role/vf-iedelivery-ci-cd-deploy-role"
  #}
}