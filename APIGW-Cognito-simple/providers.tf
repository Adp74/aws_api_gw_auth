#default
provider "aws" {
  profile = "abc"
  region = "eu-west-1"
  #assume_role {
  #  role_arn = 
  #}
}

provider "aws" {
  alias  = "use1"
  profile = "abc"
  region = "us-east-1"
  
}
