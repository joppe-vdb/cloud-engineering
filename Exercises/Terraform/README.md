# 🎓T4 - Introduction to Terraform

✅**TASK:** Now append some lines to the `s3_website.tf` file that add an index.html file with some text to the bucket.

- Use the resource [aws_s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) for this.
- Also make sure you set the correct content type for an html file.
- You should then be able to browse to the URL that is outputted by Terraform and see your static web page.
- You should also make sure that the index.html file is publicly readable. Previously, this could easily be achieved by setting the ACL to `public-read`. However, this is now deprecated and you should [use a bucket policy instead.](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-policy-language-overview.html)

✅**TASK:** Your challenge is to adapt this configuration so that the ASG is exposed to the internet and serves a simple web page, all the while following security best practices.
- Use the [Terraform Registry VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) to create a VPC with 2 public subnets and 2 private subnets. Enable NAT gateways for the private subnets.
- The EC2 VMs in the ASD should be deployed in the private subnets. 
- Use a user data script to install a web server on the VMs and serve a simple web page. Use `depends_on` to make sure the VMs are only created after the NAT gateways are up and running, otherwise the EC2 VMs will not be able to download the necessary packages.
- Create an application load balancer (ALB) in the public subnets and configure it to forward traffic to the ASG. You will need to create the alb, a target group, a listener and a autoscaling attachment for this.
- Of course, you will need to create the necessary security groups as well. Follow the principle of least privilege!
- Create a new output in `outputs.tf` that outputs the ALB DNS name. You should be able to browse to this DNS name and see your web page.

