# 🎓T4 - Introduction to Terraform

![Terraform logo](2023-10-10-13-14-25.png)

## What is Terraform
Infrastructure as code (IaC) tools allow you to manage infrastructure with configuration files rather than through a graphical user interface. IaC allows you to build, change, and manage your infrastructure in a safe, consistent, and repeatable way by defining resource configurations that you can version, reuse, and share.

Terraform is HashiCorp's infrastructure as code tool. It lets you define resources and infrastructure in human-readable, declarative configuration files, and manages your infrastructure's lifecycle. Using Terraform has several advantages over manually managing your infrastructure:

Terraform can manage infrastructure on multiple cloud platforms.
The human-readable configuration language helps you write infrastructure code quickly.
Terraform's state allows you to track resource changes throughout your deployments.
You can commit your configurations to version control to safely collaborate on infrastructure. [^1]

[^1]: Hashicorp (2022). [*What is Infrastructure as Code with Terraform?*](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code)

## Cloud Agnostic

Terraform is cloud agnostic, which means that you can use the same tool to provision multiple cloud providers. You do not have to learn and use multiple tools for each specific cloud platform (for example Cloudformation for AWS, Azure Bicep templates for Azure, kubectl and manifests for k8s, ...)

Terraform uses providers to interact with cloud platforms and other services. (Terraform was created by Hashicorp, who also created Vagrant... and Vagrant uses the concept of *providers* as well..).

Platforms supported by Terraform:
 
 - Amazon Web Services (AWS)
 - Azure
 - Google Cloud Platform (GCP)
 - VMware Vsphere
 - Docker
 - Kubernetes, including Helm charts
 - GitHub
 - Gitlab CI/CD

 
![Terraform deployment workflow](https://content.hashicorp.com/api/assets?product=tutorials&version=main&asset=public%2Fimg%2Fterraform%2Fterraform-iac.png)

## Installing Terraform

✅**TASK:** Fork this repo to your own Gitlab workspace and use it as your project directory.

Please follow [the instructions for your OS of choice.](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

Don't forget to verify your installation:

```bash
$ terraform --version  
Terraform v1.5.7
````

## The declarative configuration
 
 Terraform uses plain text files with the `.tf` extension, also called *configuration files*. These files are written in the [Hashicorp Configuration Language or HCL](https://www.terraform.io/docs/language/syntax/configuration.html).
 
 There is also a [JSON-based variant of the language](https://developer.hashicorp.com/terraform/language/syntax/json) but it is not used that often.

 These files are declarative, which means that they contain the *desired state* that we want our infrastructure to be in, and not the sequential commands that should be ran to achieve that state.

Now, let's provision our first AWS resource using Terraform.

Create a file `terraform.tf` to set up the connection:

```terraform
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_token
}
```

 As you can see: 
 - we will use the Terraform `aws` provider to connect to the AWS cloud.
 - we will connect to region `us-east-1`.
 - the variables are the AWS credentials. We need to declare the variables before we can use them.

 To keep things clean, I create a `variables.tf` file and declare the variables:

 ```terraform
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_token" {}
```

 **NOTE:** You can create multiple `.tf` files in your project without any issues. When you launch `terraform` commands, they wil automatically use all the `.tf` files in your current directory: 
 > Terraform evaluates all of the configuration files in a module, effectively treating the entire module as a single document. Separating various blocks into different files is purely for the convenience of readers and maintainers, and has no effect on the module's behavior. [^2]
 
 [^2]: Hashicorp (2022). [*Files and Directories*](https://developer.hashicorp.com/terraform/language/files)
 
 The combination of all these Terraform files is called a **Terraform module**.

 The next step is to fill in these credential variables. Terraform *can* use the `aws cli` credentials that are stored within your user's `.aws` directory. But as we know by now, we prefer to use environmental variables. Why? Because it allows us to transfer our configurations easily to Gitlab CI/CD or any other CI/CD platform.

 **NOTE:** Environmental variables that are to be used by Terraform, should always have the `TF_VAR_` prefix. So a environmental variable `TF_VAR_aws_access_key` will match with a variable called `var.aws_access_key` in a `.tf` file.

 So, we're going to create a file called `.env` to store the secrets:

 ```bash
TF_VAR_aws_access_key=ASIA53...
TF_VAR_aws_secret_key=LkqX...
TF_VAR_aws_token=FwoG...
 ```

Now, will have to read this `.env` and import this info as environmental variables.

On Windows, you can use a script like this:

```powershell
switch -File .env {
    default {
      $name, $value = $_.Trim() -split '=', 2
      if ($name -and $name[0] -ne '#') { # ignore blank and comment lines.
        Set-Item "Env:$name" $value
      }
    }
  }
```
The script read every line of the .env file, splits the values using the `=` separator and adds them to the environmental variables.

On Linux, you can use this:

```bash
set -o allexport; source .env; set +o allexport
```

Now, you should see the variables loaded when you do `env` or `Get-Item Env:`

## Terraforming

Now we can finally execute some Terraform commands. The first step when starting a new project is `terraform init`:

> The `terraform init` command initializes a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.

When you execute this, you should see Terraform initializing a lot of stuff and downloading the AWS provider plugin if it hasn't done so already.

After the initialization of our project, we will plan our deployment with `terraform plan`:

```bash
$ terraform plan

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

This makes sense, as we haven't included any actual resource declaration yet. Let's do this now! Create a file `vpc.tf` and add:

```terraform
# Create a VPC
resource "aws_vpc" "T4_network" {
  cidr_block = "10.10.1.0/24"
  tags = {
    Name = "T4_network"
  }
}
```

This will create an AWS [Virtual Private Network or VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) with a subnet 10.10.1.0/24 and a friendly name `T4_network`.

Now let's try again:

```bash
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.T4_network will be created
  + resource "aws_vpc" "T4_network" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.10.1.0/24"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_classiclink                   = (known after apply)
      + enable_classiclink_dns_support       = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "T4_network"
        }
      + tags_all                             = {
          + "Name" = "T4_network"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

These are the actions that Terraform has planned to do if we continue. This is a good time to verify if they are sane, and only continue when they are.

Let's apply our changes:
```bash
$ terraform apply
...
aws_vpc.T4_network: Creating...
aws_vpc.T4_network: Creation complete after 2s [id=vpc-00b08eae31482801b]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
Success!?!

✅**TASK:** Check if you can find the VPC in your AWS tenant.

## State

Terraform stores information about your infrastructure in a state file. This state file keeps track of resources created by your configuration and maps them to real-world resources.

### Local state

The default name for a local state file is `terraform.tfstate`. This is a JSON file that is readable. You will find your VPC resource and all the attributes in there. You can use `terraform show` to get the same output or `terraform state list` to get an list of all resources that are kept in the state at the moment:

```bash
$ terraform state list
aws_vpc.T4_network
$ terraform state show aws_vpc.T4_network
# aws_vpc.T4_network:
resource "aws_vpc" "T4_network" {
    arn                                  = "arn:aws:ec2:us-east-1:440634686927:vpc/vpc-04407216aa8253ba9"
    assign_generated_ipv6_cidr_block     = false
    cidr_block                           = "10.10.1.0/24"
    default_network_acl_id               = "acl-017a56b42de6a0167"
    default_route_table_id               = "rtb-05c36763c79b73d0b"
    default_security_group_id            = "sg-0a71d1dd0d2776559"
    dhcp_options_id                      = "dopt-00c179bffde830a07"
    enable_classiclink                   = false
    enable_classiclink_dns_support       = false
    enable_dns_hostnames                 = false
    enable_dns_support                   = true
    enable_network_address_usage_metrics = false
    id                                   = "vpc-04407216aa8253ba9"
    instance_tenancy                     = "default"
    ipv6_netmask_length                  = 0
    main_route_table_id                  = "rtb-05c36763c79b73d0b"
    owner_id                             = "440634686927"
    tags                                 = {
        "Name" = "T4_network"
    }
    tags_all                             = {
        "Name" = "T4_network"
    }
}
```

Whenever you perform a Terraform action, it will first do a `terraform refresh` to verify that the state is still in sync with the current real-world situation. Then it will compare the current state with the desired state that you have configured in the `.tf` files.

✅**TASK:** To see this in action, change the VPC subnet to 10.20.20.0/24 in the Terraform configuration files.

Let's check the plan:

```bash
$ terraform plan   
aws_vpc.T4_network: Refreshing state... [id=vpc-00b08eae31482801b]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_vpc.T4_network must be replaced
-/+ resource "aws_vpc" "T4_network" {
      ~ arn                                  = "arn:aws:ec2:us-east-1:951662005650:vpc/vpc-00b08eae31482801b" -> (known after apply)
      - assign_generated_ipv6_cidr_block     = false -> null
      ~ cidr_block                           = "10.10.1.0/24" -> "10.20.20.0/24" # forces replacement
      ~ default_network_acl_id               = "acl-096b4dc4b49d29d7e" -> (known after apply)
...
```
Wait a minute... We just want to change the subnet, why does Terraform want to replace the entire resource??? Apparently, [you can not modify the IPv4 CIDR block of a VPC without creating a new VPC](https://aws.amazon.com/premiumsupport/knowledge-center/vpc-ip-address-range/)

So, this is the best way to do it, and Terraform knows!!

![Make it so!](https://i.stack.imgur.com/MNeE7.jpg)

```bash
$ terraform apply
...

aws_vpc.T4_network: Destroying... [id=vpc-00b08eae31482801b]
aws_vpc.T4_network: Destruction complete after 0s
aws_vpc.T4_network: Creating...
aws_vpc.T4_network: Creation complete after 3s [id=vpc-037b4ace4cd2fe4ba]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```
We see that the old vpc resource was removed and the new one created!

✅**TASK:** If we delete the `vpc.tf` file, Terraform should delete the VPC as well. Please verify!

**NOTE:** If you don't want to type `yes` every time you do a `terraform apply`, you can use the `-auto-approve` flag. Very useful in CI/CD pipelines!

**NOTE:** You can use `terraform destroy` as well to delete all the provisioned resources and start anew!

### Remote state

When working in a team, multiple people will be working on the same project. It's important that all the Terraform actions are performed on the same state file, so that the state is always in sync with the real-world situation.

That is why it's best to store the state file in a remote location. Terraform has its own [Terraform Cloud](https://www.terraform.io/cloud) service, but you can also use other services like AWS S3, Azure Blob Storage, Google Cloud Storage, ...

![Terraform remote state](2023-10-10-21-47-30.png) [^remotestate]

[^remotestate]: [https://medium.com/devops-mojo/terraform-remote-states-overview-what-is-terraform-remote-state-storage-introduction-936223a0e9d0](https://medium.com/devops-mojo/terraform-remote-states-overview-what-is-terraform-remote-state-storage-introduction-936223a0e9d0)

When sharing a state file, it's important to lock it when someone is working on it. This is to prevent multiple people from making changes at the same time. Terraform Cloud has this functionality built-in, but you can also use a [DynamoDB table](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html) on AWS to lock the state file. Not all remote state backends support locking, so make sure you check the documentation.

## Buckets, lots of buckets...

Now let's deploy a static website stored in an S3 bucket. Don't forget to put in your own initials. Create a file `s3_website.tf`:

```terraform
resource "aws_s3_bucket_website_configuration" "<your-initials>website" {
  bucket = aws_s3_bucket.<your-initials>bucket.bucket

  index_document {
    suffix = "index.html"
  }

}

resource "aws_s3_bucket" "<your-initials>bucket" {
  bucket = "s3website.<your-initials>.bucket"

  tags = {
    Name        = "Website S3 bucket"
  }
}

```
**NOTE:** *You can refer between resources in a `.tf` file. This prevents you from having to hardcode values.
In the aws_s3_bucket_website_configuration resource, the line:*
```terraform
resource "aws_s3_bucket_website_configuration" "bvwebsite" {
  bucket = aws_s3_bucket.bvbucket.bucket
```
*refers to the bucket name, which is defined in the aws_s3_bucket called "bvbucket" and within the bucket attribute:*
  
```terraform
resource "aws_s3_bucket" "bvbucket" {
  bucket = "s3website.bv.bucket"
```


We can ask Terraform to output some attributes after the apply. Create a new file `outputs.tf`:

```terraform
output websiteurl {
  value = aws_s3_bucket_website_configuration.<your-initials>website.website_endpoint
}
```

In the example above, we output the website url that you can connect to to reach the site. After a `terraform apply` you will see this at the end:
```bash
aws_s3_object.bvobject: Creating...
aws_s3_object.bvobject: Creation complete after 1s [id=index.html]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

websiteurl = "s3website.bv.bucket.s3-website-us-east-1.amazonaws.com"
```
After the `terraform apply`, you can also use `terraform output <name-of-attribute>` to get the value of one specific attribute. 

```bash
$terraform output websiteurl
"s3website.bv.bucket.s3-website-us-east-1.amazonaws.com"
```
When working in a CI/CD pipeline, this can come in really handy when you have to get information out of Terraform to use in another tool. (For example, provision an EC2 machine using TF, get the public IP back, use that public IP in order to install and configure some applications using `ansible`.


✅**TASK:** Now append some lines to the `s3_website.tf` file that add an index.html file with some text to the bucket.

- Use the resource [aws_s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) for this.
- Also make sure you set the correct content type for an html file.
- You should then be able to browse to the URL that is outputted by Terraform and see your static web page.
- You should also make sure that the index.html file is publicly readable. Previously, this could easily be achieved by setting the ACL to `public-read`. However, this is now deprecated and you should [use a bucket policy instead.](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-policy-language-overview.html)

**NOTE:** You might encounter an error that prevents you from applying a public bucket policy as well. This is caused by the public access block settings that are applied on an account and a bucket level to prevent accidental public access. 
![S3 Public access block](2023-10-14-18-08-35.png =50%x)

You can use the [aws_s3_account_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_account_public_access_block) and [aws_s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) resources to disable these settings. Disabling block_public_policy and restrict_public_buckets should be sufficient.
 

## The Terraform Registry

Now that you know how to write your own `.tf` files, you can apply this all kinds of other AWS resources.

However, some setups & patterns might get quite complex to design yourself. That is why the Terraform Registry exists. It contains modules that you can reuse when needed.

For example, [this module](https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws/latest) created and maintained by Terraform and AWS allows you to easily set up an [EC2 Auto Scaling group or ASG](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html).

This module *can be used* to create and manage the ASG and the underlying resources like the launch configuration, the EC2 instances, VPC and security groups, ... You *can also* however take more control and manage some of these resources yourself. For example, you might want to create your own VPC and security groups and use them with the `asg` module by using the `vpc_zone_identifier` and `security_groups` parameters.


Let's try it. Create a file `autoscaling.tf`, add the following and run it:

```terraform
#Get AMI ID for latest Amazon Linux 2 AMI
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  image_id = data.aws_ami.amazon-linux-2.id

  instance_type = "t2.micro"

  name              = "webservers-asg"
  health_check_type = "EC2"
  #the EC2 VMs should be spread between us-east1a and us-east1b
  availability_zones = ["us-east-1a", "us-east-1b"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 1

}

```
✅**TASK:** Have a look at your AWS Management Console. Check your EC2 instances and ASG configuration. Does the result match the TF configuration? What about the VPC and security groups, how are they configured?

✅**TASK:** Your challenge is to adapt this configuration so that the ASG is exposed to the internet and serves a simple web page, all the while following security best practices.
- Use the [Terraform Registry VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) to create a VPC with 2 public subnets and 2 private subnets. Enable NAT gateways for the private subnets.
- The EC2 VMs in the ASD should be deployed in the private subnets. 
- Use a user data script to install a web server on the VMs and serve a simple web page. Use `depends_on` to make sure the VMs are only created after the NAT gateways are up and running, otherwise the EC2 VMs will not be able to download the necessary packages.
- Create an application load balancer (ALB) in the public subnets and configure it to forward traffic to the ASG. You will need to create the alb, a target group, a listener and a autoscaling attachment for this.
- Of course, you will need to create the necessary security groups as well. Follow the principle of least privilege!
- Create a new output in `outputs.tf` that outputs the ALB DNS name. You should be able to browse to this DNS name and see your web page.

<!-- ## Testing and validation

It's important to be able to validate that your deployment is working as expected. Terraform 1.5 and up provides `check` blocks that allow you to write functional tests for your infrastructure.

The following example check is a deployed web application behind a load balancer is healthy and functioning, by checking the HTTP status code.

```terraform
check "health_check" {
  data "http" "asg_health_check" {
    url = "http://${aws_alb.asg_alb.dns_name}"
    # Makes sure the EC2 instances in the ASG are deployed before doing the health check
    depends_on = [module.asg]
  }

  assert {
    condition     = data.http.asg_health_check.status_code == 200
    error_message = "${data.http.asg_health_check.url} returned an unhealthy status code"
  }
}
``` -->

<!-- ## Config-driven import

Starting with Terraform version 1.5, it is now possible to import existing resources into your Terraform state. This is a great way to start using Terraform on an existing infrastructure.

To demonstrate this, we can creat a new DynamoDB table using the AWS Management Console. Then we can use the new `import` block in a `.tf` file to automatically generate the necessary configuration and import the existing resource into our state.

✅**TASK:** Use the AWS Management Console to create a DynamoDB table called `T4dynamo`. 

Now we will create a file `dynamodb.tf` and add the following:

```terraform
import {
  to = aws_dynamodb_table.t4dynamo
  id = "T4dynamo"
}
``` -->

✅**TASK:** Last but not least, don't forget to start a merge request and put Bram and Alexander as Assignees!







