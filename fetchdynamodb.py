import boto3

s3 = boto3.client('s3')

# response = client.create_bucket(
#     ACL='private'|'public-read'|'public-read-write'|'authenticated-read',
#     Bucket='string',
#     CreateBucketConfiguration={
#         'LocationConstraint': 'af-south-1'|'ap-east-1'|'ap-northeast-1'|'ap-northeast-2'|'ap-northeast-3'|'ap-south-1'|'ap-southeast-1'|'ap-southeast-2'|'ca-central-1'|'cn-north-1'|'cn-northwest-1'|'EU'|'eu-central-1'|'eu-north-1'|'eu-south-1'|'eu-west-1'|'eu-west-2'|'eu-west-3'|'me-south-1'|'sa-east-1'|'us-east-2'|'us-gov-east-1'|'us-gov-west-1'|'us-west-1'|'us-west-2'
#     },
#     GrantFullControl='string',
#     GrantRead='string',
#     GrantReadACP='string',
#     GrantWrite='string',
#     GrantWriteACP='string',
#     ObjectLockEnabledForBucket=True|False,
#     ObjectOwnership='BucketOwnerPreferred'|'ObjectWriter'|'BucketOwnerEnforced'
# )

# print(s3.list_buckets())

# response = s3.create_bucket(Bucket="firsttrailbucketsam",CreateBucketConfiguration = {'LocationConstraint' : 'eu-central-1' })

print(s3.list_buckets())


# response = client.delete_bucket(
#     Bucket='string',
#     ExpectedBucketOwner='string'
# )

response = s3.delete_bucket(
     Bucket='firsttrailbucketsam',
 )

print(s3.list_buckets())