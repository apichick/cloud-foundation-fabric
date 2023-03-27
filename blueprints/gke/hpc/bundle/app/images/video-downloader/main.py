import requests
import os
from google.cloud import storage

storage_client = storage.Client()

BUCKET = os.getenv('BUCKET_NAME')
COLLECTION = os.getenv('COLLECTION')
ITEM = os.getenv('ITEM')
FILE = os.getenv('FILE')
URL = 'https://archive.org/download/%s/%s'


def main(bucket, collection, item, file):
    r = requests.get(URL % (item, file), allow_redirects=True)
    open(file, 'wb').write(r.content)
    blob = storage_client.bucket(bucket).blob(
        '%s/%s/%s' % (collection, item, file))
    generation_match_precondition = 0
    blob.upload_from_filename(
        file, if_generation_match=generation_match_precondition)


if __name__ == '__main__':
    main(BUCKET, COLLECTION, ITEM, FILE)
