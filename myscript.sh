#!/bin/bash

# Set your GitHub and AWS credentials
GH_USERNAME="saud73"
GH_TOKEN="mypat"
AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID="124680813683"

# Authenticate with GitHub Container Registry
echo $GH_TOKEN | docker login ghcr.io -u $GH_USERNAME --password-stdin

# Authenticate with Amazon ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Iterate through different images and move them to ECR
for IMAGE_NAME in "ivaap-java" "ivaap-postgres" "ivaap-proxy" "ivaap-admin"; do
    # Specify your GHCR image details
    GH_IMAGE="ghcr.io/$GH_USERNAME/$IMAGE_NAME:v1"
    GH_REPO=$(echo $GH_IMAGE | awk -F'/' '{split($NF,a,":"); print a[1]}')

    # Specify your ECR image details
    ECR_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$GH_REPO"

    # Extract the version from GHCR image name
    GH_VERSION=$(echo $GH_IMAGE | awk -F':' '{print $2}')

    # Pull image from GHCR
    docker pull $GH_IMAGE

    # Create ECR repository (if not exists)
    aws ecr describe-repositories --repository-names $GH_REPO --region $AWS_REGION || \
    aws ecr create-repository --repository-name $GH_REPO --region $AWS_REGION

    # Tag the image for ECR with the complete name
    docker tag $GH_IMAGE $ECR_IMAGE:$GH_VERSION

    # Push the image to ECR
    docker push $ECR_IMAGE:$GH_VERSION

  
    echo "Image $GH_IMAGE moved from GHCR to ECR successfully!"
done

