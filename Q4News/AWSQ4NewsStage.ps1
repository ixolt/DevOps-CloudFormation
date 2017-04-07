$AWSKeysPath='C:\Users\radul\Google Drive\AWSProdCreds\RaduLupanMicroservices.csv'

Connect-AWSAccount -AWSKeysPath $AWSKeysPath -Region us-west-2 -Profile microservices


## All CloudFront templates are located in the S3 bucket https://s3.amazonaws.com/q4devops-cf-templates

## 1. Create VPC with 2 x public subnets and 2 x private subnets

$CFStackParams1=@{'StackName'='Q4News-Stage';`
                 'OnFailure'='ROLLBACK';`
                 'Capability'='CAPABILITY_IAM';`
                 'TemplateURL'='https://s3.amazonaws.com/q4devops-cf-templates/q4news-vpc-template.json';`
                }


New-CFNStack @CFStackParams1 `
             -Parameter @( @{ ParameterKey="InstanceTenancy"; ParameterValue="default"}, `
                           @{ ParameterKey="Environment"; ParameterValue="Stage"})


## 2. Create the 2 x FTP servers in each public subnets, create failover DNS recordsin Route 53 for q4app.net domain: ftp-news.q4app.net


$CFStackParams2=@{'StackName'='Q4News-Stage-FTP';`
                 'OnFailure'='ROLLBACK';`
                 'Capability'='CAPABILITY_IAM';`
                 'TemplateURL'='https://s3.amazonaws.com/q4devops-cf-templates/q4news-stage-ftp-template.json';`
                }



New-CFNStack @CFStackParams2 `
             -Parameter @( @{ ParameterKey="InstanceType"; ParameterValue="t2.micro"}, `
                           @{ ParameterKey="VPCID"; ParameterValue="vpc-98bae5ff"}, `
                           @{ ParameterKey="AppSubnets"; ParameterValue="subnet-c087eda7,subnet-2444c86d"},`
                           @{ ParameterKey="KeyName"; ParameterValue="MicroservicesOregon"}, `
                           @{ ParameterKey="APPGroupName"; ParameterValue="FTP"}, `
                           @{ ParameterKey="OctopusEnvironment"; ParameterValue="Microservices Stage"}, `
                           @{ ParameterKey="BootstrapScriptLocation"; ParameterValue="q4news-bootstrap"})


## 3. Manually install Filezilla Server on both EC2 instances provisioned in step 2. I have not been able to find a way to install FileZilla silently.

## 4. Create user Aquire on BOTH FTP servers in FileZilla, point to home folder C:\FTPRoot\Aquire and assign permissions as follows:
##      4.1 Files: Read, Write, Delete
##      4.2 Directories: Create, List, +Subdirs

## 5. Configure Filezilla: 
##      5.1 Edit menu->Settings->Passive mode settings->Use Custom Range: 50000-51000.
##      5.2 External Server IP Address for passive mode transfer, select Use the following IP box and type in the public IP of the FTP server.


## 6. Create RDS PostgresSQL instance: db.m4.large, 100 GB SSD drive, MultiAZ

$CFStackParams3=@{'StackName'='Q4News-Stage-RDS';`
                 'OnFailure'='ROLLBACK';`
                 'Capability'='CAPABILITY_IAM';`
                 'TemplateURL'='https://s3.amazonaws.com/q4devops-cf-templates/q4news-rds-template.json';`
                }



New-CFNStack @CFStackParams3 `
             -Parameter @( @{ ParameterKey="VPCID"; ParameterValue="vpc-98bae5ff"}, `
                           @{ ParameterKey="AppSubnets"; ParameterValue="subnet-c199f3a6,subnet-bb4ac6f2"},`
                           @{ ParameterKey="DBName"; ParameterValue="newsservicedb"}, `
                           @{ ParameterKey="DBUsername"; ParameterValue="root"}, `
                           @{ ParameterKey="DBPassword"; ParameterValue="PleaseChangeMe!"}, `
                           @{ ParameterKey="DBClass"; ParameterValue="db.m4.large"}, `                           
                           @{ ParameterKey="DBAllocatedStorage"; ParameterValue="100"})

## Create an EC2 instance in one of the public subnets of Q4News-Stage VPC and install the PostgreSQL pgadmin client 
## https://www.postgresql.org/ftp/pgadmin3/release/v1.22.2/win32/
## Run the following SQL scripts on the newsservicedb in order: