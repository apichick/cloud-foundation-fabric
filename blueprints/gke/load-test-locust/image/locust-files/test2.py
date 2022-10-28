import time
import logging
from locust import HttpUser, task, between

class BookInfoReviewsUser(HttpUser):

    host = "http://reviews.bookinfo.svc.cluster.local:9080"

    wait_time = between(5, 9)

    @task
    def book_details(self):
        with self.client.get("/reviews/1", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                logging.info('Response code is ' + str(response.status_code))
