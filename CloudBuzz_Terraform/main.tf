provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "us-east-1"
}
#-----------------Lambda--------------------------
resource "aws_lambda_function" "terraform_lambda_func" {
filename                       = "${path.module}/python/hello-python.zip"
function_name                  = "terraform_lambda_func"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index.lambda_handler"
runtime                        = "python3.9"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

#-------------SNS-----------------
resource "aws_sns_topic" "my_tf_sns_topic" {
  name = "my_tf_sns_topic"
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.my_tf_sns_topic.arn
  protocol  = "email"
  endpoint  = "azar375@gmail.com"
}

resource "aws_lambda_function_event_invoke_config" "terraform_lambda_invoke" {
  function_name = aws_lambda_function.terraform_lambda_func.function_name

  destination_config {
    on_failure {
      destination = aws_sns_topic.my_tf_sns_topic.arn
    }

    on_success {
      destination = aws_sns_topic.my_tf_sns_topic.arn
    }
  }
}


#------------Premission policy---------

resource "aws_iam_policy" "iam_policy_for_lambda" {
 
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}

#---------------http api gateway---------------
  
resource "aws_apigatewayv2_api" "lambda" {
  name          = "apigw-http-lambda"
  protocol_type = "HTTP"
  description   = "API Gwy HTTP API and AWS Lambda function"

}


resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "terraform_lambda_func" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.terraform_lambda_func.invoke_arn
  integration_type   = "AWS_PROXY"
}

resource "aws_apigatewayv2_route" "any" {
  api_id = aws_apigatewayv2_api.lambda.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.terraform_lambda_func.id}"
}


resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}



#---------------premission role---------------

resource "aws_iam_role" "lambda_role" {
name   = "Spacelift_Test_Lambda_Function_Role"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}




data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "${path.module}/python/"
output_path = "${path.module}/python/hello-python.zip"
}


