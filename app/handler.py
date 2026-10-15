import json

APP_VERSION = "1.0.0"

def handler(event, context):

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "status": "ok",
            "version": APP_VERSION,
            "message": "Application is running"
        })
    }

