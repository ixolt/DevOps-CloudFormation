
## All CloudFront templates are located in the S3 bucket https://s3.amazonaws.com/q4-devops-cfn-templates

## 1. Create master stacj Q4News-Stage that calls multiple child CloudFormation from S3 bucket

$CFStackParams1=@{'StackName'='Q4News-Dev';`
                 'OnFailure'='ROLLBACK';`
                 'Capability'='CAPABILITY_IAM';`
                 'TemplateURL'='https://s3.amazonaws.com/q4-devops-cfn-templates/q4news/q4news-master.json';`
                }


New-CFNStack @CFStackParams1 `
             -Parameter @( @{ ParameterKey="InstanceTenancy"; ParameterValue="default"}, `
                           @{ ParameterKey="Environment"; ParameterValue="dev"}, `
                           @{ ParameterKey="InstanceType"; ParameterValue="t2.micro"}, `
                           @{ ParameterKey="KeyName"; ParameterValue="MicroSvcDevNVirginia"}, `
                           @{ ParameterKey="OctopusEnvironment"; ParameterValue="Microservices Dev"}, `
                           @{ ParameterKey="BootstrapScriptLocation"; ParameterValue="q4news-ftpbootstrap"},`
                           @{ ParameterKey="DBClass"; ParameterValue="db.m4.large"},`
                           @{ ParameterKey="DBPassword"; ParameterValue="VeryByDown0$!"}                           
                         )
                           

## 2. Manually install Filezilla Server on both EC2 instances provisioned in step 2. I have not been able to find a way to install FileZilla silently.

## 3. Create user Aquire on BOTH FTP servers in FileZilla, point to home folder C:\FTPRoot\Aquire and assign permissions as follows:
##      3.1 Files: Read, Write, Delete
##      3.2 Directories: Create, List, +Subdirs

## 4. Configure Filezilla: Edit menu->Settings->Passive mode settings->Use Custom Range: 50000-51000.
