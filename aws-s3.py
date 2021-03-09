import boto3

s3 = boto3.resource('s3',endpoint_url='http://5375c51dec85:4566',aws_access_key_id ='foo',aws_secret_access_key ='bar')

for bucket in s3.buckets.all():
    print(bucket)