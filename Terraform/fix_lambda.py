import json
import boto3
def lambda_handler(event, context):
    print(event[0]['payload']['value'])
    client = boto3.client('iot-data')
    response = client.update_thing_shadow(
        thingName='air-quality-system-1',
        payload=json.dumps({"state": {"desired": {"": "10"} }})
    )
     response = client.get_thing_shadow(
        thingName='air-quality-system-1'
    )
    print(response)