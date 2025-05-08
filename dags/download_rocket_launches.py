import json
import pathlib
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.hooks.http_hook import HttpHook
from airflow.utils.dates import days_ago
import requests
from requests.exceptions import MissingSchema, ConnectionError

default_args = {
    'owner': 'airflow',
}

with DAG(
    dag_id="download_rocket_launches",
    description="Download rocket pictures of recently launched rockets.",
    start_date=days_ago(2),
    schedule_interval="@daily",
    catchup=False,
    default_args=default_args,
) as dag:

    def fetch_launch_data(**kwargs):
        """Use HttpHook to fetch launch data and save to a file"""
        http = HttpHook(method='GET', http_conn_id='rocket_api')
        response = http.run(endpoint='launch/upcoming')
        launches = response.json()

        # Save to file so next task can use it
        with open("/tmp/launches.json", "w") as f:
            json.dump(launches, f)

    def download_images(**kwargs):
        """Download rocket images from JSON file"""
        pathlib.Path("/tmp/images").mkdir(parents=True, exist_ok=True)

        with open("/tmp/launches.json") as f:
            launches = json.load(f)
            image_urls = [launch["image"] for launch in launches["results"] if launch["image"]]

        for url in image_urls:
            try:
                response = requests.get(url)
                filename = url.split("/")[-1]
                target_path = f"/tmp/images/{filename}"
                with open(target_path, "wb") as f:
                    f.write(response.content)
                print(f"Downloaded {url}")
            except MissingSchema:
                print(f"Invalid URL: {url}")
            except ConnectionError:
                print(f"Failed to connect: {url}")

    fetch_task = PythonOperator(
        task_id="fetch_launch_data",
        python_callable=fetch_launch_data,
        provide_context=True,
    )

    download_task = PythonOperator(
        task_id="download_images",
        python_callable=download_images,
        provide_context=True,
    )

    notify_task = BashOperator(
        task_id="notify",
        bash_command='echo "There are now $(ls /tmp/images/ | wc -l) images."',
    )

    fetch_task >> download_task >> notify_task
