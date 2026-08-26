#!/bin/bash
set -euo pipefail

echo "Creating queues..."

CATEGORY_QUEUE_URL=$(
  awslocal sqs create-queue \
    --queue-name gig-category-events \
    --query QueueUrl \
    --output text
)

CHAT_QUEUE_URL=$(
  awslocal sqs create-queue \
    --queue-name gig-chat-events \
    --query QueueUrl \
    --output text
)

NOTIFICATION_QUEUE_URL=$(
  awslocal sqs create-queue \
    --queue-name gig-notification-events \
    --query QueueUrl \
    --output text
)

NOTIFICATION_QUEUE_ARN=$(
  awslocal sqs get-queue-attributes \
    --queue-url "$NOTIFICATION_QUEUE_URL" \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text
)

echo "Loading notification lambda environment..."
set -a
source /etc/localstack/init/ready.d/lambda/.env.example
set +a

echo "Deploying notification Lambda..."
awslocal lambda create-function \
  --function-name notification-lambda \
  --runtime provided.al2023 \
  --handler bootstrap \
  --zip-file fileb:///etc/localstack/init/ready.d/lambda/lambda.zip \
  --role arn:aws:iam::000000000000:role/lambda-execution-role \
  --environment "Variables={APP_ENV=${APP_ENV},DB_HOST=${DB_HOST},DB_PORT=${DB_PORT},DB_USER=${DB_USER},DB_PASSWORD=${DB_PASSWORD},DB_NAME=${DB_NAME},DB_SSLMODE=${DB_SSLMODE},FIREBASE_CREDENTIALS_PATH=${FIREBASE_CREDENTIALS_PATH}}"

awslocal lambda create-event-source-mapping \
  --function-name notification-lambda \
  --event-source-arn "$NOTIFICATION_QUEUE_ARN"

echo "Done"