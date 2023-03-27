import internetarchive
import yaml
import os
from kubernetes import client, config, utils
from string import Template

BUCKET = os.getenv('BUCKET')
COLLECTION = os.getenv('COLLECTION')
FORMAT = os.getenv('FORMAT')

config.load_incluster_config()
k8s_client = client.ApiClient()

file = open('job.yaml', 'r')
workload_tpl = file.read()


def create_job(bucket, collection, item, file):
    s = Template(workload_tpl).substitute(
        bucket=bucket, collection=collection, item=item, file=file)
    o = yaml.safe_load(s)
    utils.create_from_dict(k8s_client, o)


def create_jobs(bucket, collection, format):
    results = internetarchive.search_items('%s' % collection)
    for result in results:
        item = internetarchive.get_item(result['identifier'])
        files = item.get_files(formats=[format])
        for file in files:
            create_job(bucket, collection, file.identifier, file.name)


def main(bucket, collection, format):
    create_jobs(bucket=bucket, collection=collection, format=format)


if __name__ == '__main__':
    main(BUCKET, COLLECTION, FORMAT)
