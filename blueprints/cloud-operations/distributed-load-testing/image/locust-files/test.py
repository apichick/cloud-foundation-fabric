import logging
from locust import HttpUser, LoadTestShape, task

class CustomUser(HttpUser):

    host = 'http://nginx.default.svc.cluster.local'

    @task
    def productpage(self):
        with self.client.get('/', catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                logging.info('Response code is ' + str(response.status_code))
                response.failure('Response code is ' + str(response.status_code))

class CustomLoadShape(LoadTestShape):

    stages = []

    num_stages = 20
    stage_duration = 60
    spawn_rate = 3
    new_users_per_stage = 3

    for i in range (1, num_stages + 1):
        stages.append({
            'duration': 60 * i,   
            'users': 3 * i,
            'spawn_rate': spawn_rate
        })

    for i in range(1, num_stages):
        stages.append({
            'duration':60 * (num_stages + i),   
            'users': 3 * (num_stages - i),
            'spawn_rate': spawn_rate
        })

    def tick(self):
        run_time = self.get_run_time()
        for stage in self.stages:
            if run_time < stage['duration']:
                tick_data = (stage['users'], stage['spawn_rate'])
                return tick_data
        return None
