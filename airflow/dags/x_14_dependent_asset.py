from airflow.sdk import dag, task, asset
from pendulum import datetime
import os
import pendulum
from asset_13 import fetch_data

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@asset(
    schedule=fetch_data,
    uri="/opt/airflow/logs/data/data_processed.txt",
    name="process_data"
)
def process_data(self):

    os.makedirs(os.path.dirname(self.uri), exist_ok=True)

    with open("/opt/airflow/logs/data/data_extract.txt", 'r') as file:
        data = file.read()
        print(f"\n\nData from data_extract.txt: {data}\n\n")

    with open(self.uri, 'w') as file:
        file.write(f"Data is processed: {data}")

    print(f"Data was processed in {self.uri}")
    

