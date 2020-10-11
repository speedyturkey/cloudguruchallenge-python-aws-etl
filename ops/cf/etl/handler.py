import csv
import datetime
import os
import urllib.request
from typing import Dict, List, Tuple

import boto3

NYT_URL = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us.csv"
HOPKINS_URL = "https://raw.githubusercontent.com/datasets/covid-19/master/data/time-series-19-covid-combined.csv"
DYNAMO_DB_TABLE_NAME = os.environ.get("DYNAMO_DB_TABLE_NAME")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

sns_resource = boto3.resource("sns")
sns_topic = sns_resource.Topic(SNS_TOPIC_ARN)


def download_csv_data(url: str) -> List[Dict]:
    print(f"downloading {url}")
    response = urllib.request.urlopen(url)
    raw_data = [line.decode("utf-8") for line in response.readlines()]
    return [row for row in csv.DictReader(raw_data)]


def to_datetime(date: str) -> datetime.datetime:
    return datetime.datetime.strptime(date, "%Y-%m-%d")


def extract() -> List[Dict]:
    """
    Download and return latest NYT Covid Data
    """
    return download_csv_data(NYT_URL)


def transform(covid_data: List[Dict]) -> List[Dict]:
    """
    Transform source data:
        (1) Convert date strings to datetime objects
        (2) Add Johns Hopkins' daily recovered count.
        (3) Filter out any dates not present in Johns Hopkins' data set
    """
    hopkins_data = download_csv_data(HOPKINS_URL)
    recovery_data = {
        to_datetime(row["Date"]): row["Recovered"]
        for row in hopkins_data
        if row["Country/Region"] == "US"
    }
    transformed = []
    for row in covid_data:
        row["date"] = to_datetime(row["date"])
        # if row["date"] is not None, date exists in both data sources
        if recovery_data.get(row["date"]):
            row["recovered"] = recovery_data.get(row["date"])
            transformed.append(row)
    return transformed


def scan_existing_data(table):
    """
    Given a <dynamodb.Table> object, scan and return all items.
    """
    response = table.scan()
    http_status_code = response.get("ResponseMetadata", {}).get("HTTPStatusCode")
    if http_status_code == 200:
        return response.get("Items")
    else:
        raise Exception(
            f"Unable to scan {table.name}, received status code {http_status_code}"
        )


def load(new_data: List[Dict]) -> Tuple:
    """
    Load items to DynamoDB, and return count of new and changed records.
    """
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(DYNAMO_DB_TABLE_NAME)
    existing_data = {row["date"]: row for row in scan_existing_data(table)}
    print(f"about to load {len(new_data)} records to {table}")
    print(f"there are {len(existing_data)} existing records")
    new_count = 0
    updated_count = 0
    with table.batch_writer() as batch:
        for row in new_data:
            row["date"] = str(row["date"])
            exists = existing_data.get(row["date"])
            if not exists:
                new_count += 1
            if exists and row != exists:
                updated_count += 1
            # Creates a new item, or replaces an old item with a new item.
            # If an item that has the same primary key as the new item already exists in the specified table,
            # the new item completely replaces the existing item
            batch.put_item(
                Item={
                    "date": row["date"],
                    "cases": row["cases"],
                    "deaths": row["deaths"],
                    "recovered": row["recovered"],
                }
            )
    print(f"new records: {new_count}; updated records: {updated_count}")
    return new_count, updated_count


def notify_success(new, updated) -> None:
    """
    Publish success message to SNS topic with email subscription
    """
    sns_topic.publish(
        Subject="Covid Data ETL Completed - Success",
        Message=f"Daily Data Updated\nCount of New Records: {new} \nCount of Updated Records: {updated}\n",
    )


def notify_failure(error: str) -> None:
    """
    Publish failure message to SNS topic with email subscription
    """
    sns_topic.publish(Subject="Covid Data ETL Completed - Failure", Message=error)


def main(event, context) -> None:
    """
    Perform extract, transform, and load of NYT Covid Data.
    If no errors, send success notification.
    Otherwise, catch error and send failure notification.
    """
    try:
        new, updated = load(transform(extract()))
        notify_success(new, updated)
    except Exception as exc:
        notify_failure(str(exc))


if __name__ == "__main__":
    main(None, None)
