
# lets us run aws things
provider "aws" {
    version = "~> 3.0"
    region = "us-west-2"
}

# creates ecr repo
#         aws product          internal tf name   
resource "aws_ecr_repository" "go-sample" {
    name = "hello" # name of the image we want to push uo
}

# TODO: problem, my dev user doesn't have access to creating users
# create user to access ecr repo
#                        # internal tf name       
resource "aws_iam_user" "circleci_user" {
  name = "brenna_circleci" # aws user name
  path = "/" # it's complicated

  tags = {
    user = "brenna_hd"
  }
}

resource "aws_iam_access_key" "circleci_user" {
  user = aws_iam_user.circleci_user.name
}

resource "aws_iam_user_policy" "circleci_pol" {
  name = "brenna_circle_ci_pol"
  user = aws_iam_user.circleci_user.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImageScanFindings",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:GetDownloadUrlForLayer",
                "ecr:ListTagsForResource",
                "ecr:UploadLayerPart",
                "ecr:ListImages",
                "ecr:PutImage",
                "ecr:UntagResource",
                "ecr:BatchGetImage",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeImages",
                "ecr:TagResource",
                "ecr:DescribeRepositories",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:GetLifecyclePolicy"
            ],
            "Resource": "arn:aws:ecr:us-west-2:102179876835:repository/hello"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        }
    ]
}
EOF
}

# accesses attribute of created resource for our use
output "circleci_access_key" {
    value = aws_iam_access_key.circleci_user.id
}

output "circleci_secret_key" {
    value = aws_iam_access_key.circleci_user.secret
}