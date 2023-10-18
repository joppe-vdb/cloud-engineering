output websiteurl {
  value = aws_s3_bucket_website_configuration.jvdbwebsite.website_endpoint
}


output alb_dns_name {
  value = module.alb.lb_dns_name
}
