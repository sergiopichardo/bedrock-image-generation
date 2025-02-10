import json
import boto3
import base64
import datetime
import os

# Create client connection with Bedrock and S3 Services
client_bedrock = boto3.client('bedrock-runtime')
client_s3 = boto3.client('s3')

def handler(event, context): 
    try:
        # Extract image generation prompt from API Gateway request
        request_body = json.loads(event['body'])
        image_prompt = request_body['prompt']

        # Call Bedrock API to generate image from prompt
        bedrock_response = client_bedrock.invoke_model(
            contentType='application/json', 
            accept='application/json',
            modelId=os.environ['BEDROCK_MODEL_ID'],
            body=json.dumps({
                "text_prompts": [{"text": image_prompt}],
                "cfg_scale": 10,
                "steps": 30,
                "seed": 0
            }))
           
        # Parse response and extract image data
        image_response_data = json.loads(bedrock_response['body'].read())

        # Decode base64 image data to binary
        image_base64 = image_response_data['artifacts'][0]['base64']
        decoded_image = base64.b64decode(image_base64)
        
        # Generate unique filename with timestamp
        image_filename = 'generated-image-' + datetime.datetime.today().strftime('%Y-%m-%d-%H-%M-%S')
            
        # Store generated image in S3 bucket
        client_s3.put_object(
            Bucket=os.environ['BUCKET_NAME'],
            Body=decoded_image,
            Key=image_filename)

        # Create temporary download URL valid for 1 hour
        image_download_url = client_s3.generate_presigned_url(
            'get_object', 
            Params={'Bucket': os.environ['BUCKET_NAME'], 'Key': image_filename}, 
            ExpiresIn=3600)
            
        # Return success response with download URL
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'url': image_download_url
            })
        }
        
    except Exception as e:
        # Log error and return error response
        print(f"Error: {str(e)}")  # This will log to CloudWatch
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }