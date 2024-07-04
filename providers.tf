terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
        }
    }
}

#Configure the AWS provider
provider "aws" {
    region = "us-est-2"
    shared_credentials_files = "~/.aws/credentials"
    profile = "credentials"
}
