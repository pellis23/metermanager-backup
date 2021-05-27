import sys
def handler(event, context):
    return 'AWS Lambda Python finished' + sys.version + '!'
