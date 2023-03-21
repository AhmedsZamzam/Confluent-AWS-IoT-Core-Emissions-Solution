import json
import boto3
def lambda_handler(event, context):
    client = boto3.client('iot-data')
    response = client.update_thing_shadow(
        thingName='air-quality-system-1',
        payload=json.dumps({"state": {"desired": {"": event['value']} }})
    )
    response = client.get_thing_shadow(
        thingName='air-quality-system-1'
    )
    print(response)