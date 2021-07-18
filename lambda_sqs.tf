resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
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
resource "aws_iam_policy" "policy" {
  name        = "lambda-policy"
  description = "lambda policy"
  policy      = file("policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_lambda_function" "Producer" {
  filename      = "Lamda-SourceCode.zip"
  function_name = "Producer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "Interview::Interview.Producer::ProducerHandler"
  timeout       = 15

  source_code_hash = filebase64sha256("Lamda-SourceCode.zip")
  runtime          = "dotnetcore3.1"
}

resource "aws_lambda_function" "Consumer" {
  filename      = "Lamda-SourceCode.zip"
  function_name = "Consumer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "Interview::Interview.Consumer::ConsumerHandler"
  timeout       = 15

  source_code_hash = filebase64sha256("Lamda-SourceCode.zip")
  runtime          = "dotnetcore3.1"
}

resource "aws_sqs_queue" "terraform_queue_interview" {
  name                      = "interview"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.terraform_queue_interview.arn
  enabled          = true
  function_name    = aws_lambda_function.Consumer.arn
}
