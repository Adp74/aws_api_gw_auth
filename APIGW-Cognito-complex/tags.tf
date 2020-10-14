locals {
  common_tags = {
    Environment     = var.ENV
    Project         = var.PROJECT
    ManagedBy       = "albamaria.diazfernandez@vodafone.com"
    Confidentiality = "C2"
    TaggingVersion  = "V2.3"
    SecurityZone    = "A"
  }
}