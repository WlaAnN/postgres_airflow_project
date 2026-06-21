from airflow.sdk import dag, task, asset
from pendulum import datetime
import os
import pendulum

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@asset(
    schedule="@daily",
    uri="/opt/airflow/logs/data/data_extract.txt",
    name="fetch_data"
)
def fetch_data(self):

    os.makedirs(os.path.dirname(self.uri), exist_ok=True)

    with open(self.uri, 'w') as file:
        file.write(f"Data is fetched")

    print(f"Data was fetched in {self.uri}")
    

