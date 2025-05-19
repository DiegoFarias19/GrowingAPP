import functions_framework
import os
from google.cloud import bigquery
from datetime import datetime

BIGQUERY_PROJECT_ID = os.environ.get("BIGQUERY_PROJECT_ID")
BIGQUERY_DATASET_ID = os.environ.get("BIGQUERY_DATASET_ID")
BIGQUERY_TABLE_ID = os.environ.get("BIGQUERY_TABLE_ID")

bq_client = None
if all([BIGQUERY_PROJECT_ID, BIGQUERY_DATASET_ID, BIGQUERY_TABLE_ID]):
    try:
        bq_client = bigquery.Client(project=BIGQUERY_PROJECT_ID)
        print("BIGQUERY client initialized successfully.")
    except Exception as e:
        print("fError initializing BIGQUERY client: {e}")

@functions_framework.http
def main(request):
    if not all([BIGQUERY_PROJECT_ID, BIGQUERY_DATASET_ID, BIGQUERY_TABLE_ID]) or bq_client is None:
        print("Error: BigQuery configuration is incomplete or client not initialized.")
        return {
            "status": "error",
            "message": "Server configuration error (missing BigQuery environment variables or client issue)."
        }, 500

    if request.method != 'GET':
        print(f"Method not allowed: {request.method}")
        return {"status": "error", "message": "Method not allowed. Use GET."}, 405
    print(f"Received GET request to list data from {BIGQUERY_PROJECT_ID}.{BIGQUERY_DATASET_ID}.{BIGQUERY_TABLE_ID}")

    sql_query = f"""
        SELECT
            timestamp,
            temperature,
            humidity,
            relay_state
        FROM `{BIGQUERY_PROJECT_ID}.{BIGQUERY_DATASET_ID}.{BIGQUERY_TABLE_ID}`
        ORDER BY timestamp DESC
        LIMIT 1000
    """

    rows = []
    try:
        query_job = bq_client.query(sql_query)
        results = query_job.result()

        for row in results:
            row_dict = dict(row)

            for key, value in row_dict.items():
                if isinstance(value, datetime):
                    row_dict[key] = value.isoformat()

            rows.append(row_dict)
        print(f"BigQuery query completed. Retrieved {len(rows)} rows.")
        return {
            "status": "success",
            "message": f"Retrieved {len(rows)} records.",
            "data": rows
        }, 200
    
    except Exception as e:
        print(f"Error querying BigQuery: {e}")
        return {
            "status": "error",
            "message": f"Error retrieving data from BigQuery."
        }, 500

    