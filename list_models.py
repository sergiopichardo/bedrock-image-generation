import boto3

def list_bedrock_models():
    # Create a bedrock client (not runtime client)
    bedrock = boto3.client('bedrock')
    
    try:
        # Get list of all available models
        response = bedrock.list_foundation_models()
        
        # Extract and print model information
        for model in response['modelSummaries']:
            print(f"Model ID: {model['modelId']}")
            print(f"Provider: {model['providerName']}")
            print(f"Model Name: {model['modelName']}")
            print("-" * 50)
            
        return response['modelSummaries']
    except Exception as e:
        print(f"Error listing models: {e}")
        return []
    
list_bedrock_models()