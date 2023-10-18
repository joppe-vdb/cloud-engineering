resource "aws_s3_bucket_website_configuration" "jvdbwebsite" {
  bucket = aws_s3_bucket.jvdbbucket.bucket
  index_document {
     suffix = "index.html"
  }
}


resource "aws_s3_bucket" "jvdbbucket" {
  bucket = "s3website.jvdb.bucket"
  tags = {
    Name = "Website S3 bucket"
  }
  
}

resource "aws_s3_object" "jvdbobject" {
  bucket = "s3website.jvdb.bucket"
  key = "index.html"
  source = "/home/joppe/Documents/index.html"
  content_type = "text/html"
}


resource "aws_s3_bucket_policy" "allow_all_access" {
  bucket = "s3website.jvdb.bucket"
  policy = data.aws_iam_policy_document.allow_all_access.json
}


data "aws_iam_policy_document" "allow_all_access" {
  statement {
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.jvdbbucket.arn}/index.html",
    ]
  }
}
