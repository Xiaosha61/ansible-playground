# deploy EC2
# aws cloudformation deploy \
#     --template-file cloud-formation/template.yml \
#     --stack-name my-stack

# deploy S3 bucket and override the manually created one
S3_BUCKET_NAME="xiaosha-website"
aws cloudformation deploy \
    --template-file cloud-formation/cloudfront.yml \
    --stack-name production-distro \
    --parameter-overrides PipelineID="${S3_BUCKET_NAME}" \ # Name of the S3 bucket you created manually.
    --tags project=udapeople &