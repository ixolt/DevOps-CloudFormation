

## All CloudFront templates are located in the S3 bucket https://s3.amazonaws.com/q4-devops-cf-templates/q4cdn

$CFStackParams=@{'StackName'='Q4CDN';`
                 'OnFailure'='ROLLBACK';`
                 'Capability'='CAPABILITY_IAM';`
                 'TemplateURL'='https://s3.amazonaws.com/q4-devops-cf-templates/q4cdn/q4cdn-master.template';`
                }


New-CFNStack @CFStackParams `
             -Parameter @( @{ ParameterKey="InstanceTenancy"; ParameterValue="default"}, `
                           @{ ParameterKey="AWSAccount"; ParameterValue="Stage"}, `
                           @{ ParameterKey="InstanceType"; ParameterValue="t2.micro"}, `
                           @{ ParameterKey="SSHKeyPair"; ParameterValue="StagingOhio"}, `
                           @{ ParameterKey="AppGroupName"; ParameterValue="ContentCache"}, `
                           @{ ParameterKey="AppEnvironment"; ParameterValue="test"},`
                           @{ ParameterKey="BackEnd"; ParameterValue="stage"},`
                           @{ ParameterKey="SSHLocation"; ParameterValue="206.223.161.250/32"},`
                           @{ ParameterKey="SplunkAdminPassword"; ParameterValue="Passw0rd!"},`
                           @{ ParameterKey="GitHubOwner"; ParameterValue="q4mobile"},`
                           @{ ParameterKey="GitHubOAuthToken"; ParameterValue="b3ed205083e45aeac96c364655cdc87419a4c18b"},`
                           @{ ParameterKey="GitHubRepo"; ParameterValue="DevOps-NginxConfiguration"}                           
                         )
                           

