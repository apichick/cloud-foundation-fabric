import yaml
import os
from flask import Flask, request, jsonify
from kubernetes import client, config, utils
from string import Template

PORT = int(os.getenv('PORT', 5000))
DEBUG = os.getenv('DEBUG', False)

app = Flask(__name__)

config.load_incluster_config()
k8s_client = client.ApiClient()

file = open('job.yaml', 'r')
workload_tpl = file.read()

def create_job(bucket, collection, format):
    s = Template(workload_tpl).substitute(
        bucket=bucket, collection=collection, format=format)
    o = yaml.safe_load(s) 
    utils.create_from_dict(k8s_client, o)

@app.route('/downloads', methods=['POST'])
def downloads():
    payload = request.get_json()
    create_job(bucket=payload['bucket'], collection=payload['collection'], format=payload['format'])
    return jsonify(message='Download scheduled'), 201
    
@app.route('/status', methods=['GET'])
def status():
    return "Server ready", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=DEBUG)
