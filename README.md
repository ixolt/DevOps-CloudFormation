# DevOps-CloudFormation

These templates are being developed and used to create various environments in
AWS.

## Generic 

The templates in this folder aren't specific to any product. They are generic
enough where they don't need to be updated much.

NOTE: The VPC template does need to be updated when being deployed (the CIDR
mappings)

## Q4EuroInvestor

These templates are currently being used to create staging and production
environments for the Q4EuroInvestor product. They are a bit in flux right now
and are not considered stable.

They are focused on creating web, app (but not for long) and db servers.

## Q4Web

These templates are currently being used to create a staging environment in AWS
for the Q4 Web product. They are reasonably stable but do require some
additional work to make them easier to use and understand.

They are focused on creating web,app and database servers capable of hosting
the various web and application services that power Q4 Web.
