import os
import functions_framework
from google.cloud import bigquery
from flask import jsonify
from datetime import datetime, timedelta

PROJECT_ID = os.environ.get("BIGQUERY_PROJECT_ID", "iot-growing-app")
DATASET_ID = os.environ.get("BIGQUERY_DATASET_ID", "sensor_data")
TABLE_ID = os.environ.get("BIGQUERY_TABLE_ID", "sensor_readings")

client = bigquery.Client(project=PROJECT_ID)

@functions_framework.http
def list_sensor_readings(request):
    headers = { 'Access-Control-Allow-Origin': '*' }
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    device_id = request.args.get('id')
    date_str = request.args.get('date')

    if not device_id:
        return (jsonify({"error": "El parámetro 'id' del dispositivo es requerido."}), 400, headers)

    table_ref = f"`{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}`"
    timezone = "America/Santiago"

    try:
        if date_str:
            display_date_str = date_str
            start_timestamp_str = f"{date_str} 00:00:00"
            end_timestamp_str = f"{date_str} 23:59:59"

            start_timestamp_query = "SELECT TIMESTAMP(@start_ts, @timezone) as ts"
            end_timestamp_query = "SELECT TIMESTAMP(@end_ts, @timezone) as ts"

            job_config_start = bigquery.QueryJobConfig(query_parameters=[
                bigquery.ScalarQueryParameter("start_ts", "STRING", start_timestamp_str),
                bigquery.ScalarQueryParameter("timezone", "STRING", timezone)
            ])
            job_config_end = bigquery.QueryJobConfig(query_parameters=[
                bigquery.ScalarQueryParameter("end_ts", "STRING", end_timestamp_str),
                bigquery.ScalarQueryParameter("timezone", "STRING", timezone)
            ])

            start_timestamp = list(client.query(start_timestamp_query, job_config=job_config_start))[0].ts
            end_timestamp = list(client.query(end_timestamp_query, job_config=job_config_end))[0].ts
        else:
            max_timestamp_query = f"""
                SELECT MAX(timestamp) as max_ts
                FROM {table_ref}
                WHERE device_id = @device_id AND LOWER(metric_type) IN ('temperature', 'humidity')
            """
            job_config = bigquery.QueryJobConfig(
                query_parameters=[bigquery.ScalarQueryParameter("device_id", "STRING", device_id)]
            )
            max_ts_result = list(client.query(max_timestamp_query, job_config=job_config))

            if not max_ts_result or not max_ts_result[0].max_ts:
                return (jsonify({"displayDate": "No hay datos", "readings": []}), 200, headers)

            end_timestamp = max_ts_result[0].max_ts
            start_timestamp = end_timestamp - timedelta(hours=24)
            display_date_str = end_timestamp.strftime('%Y-%m-%d')

        data_query = f"""
            SELECT
                LOWER(metric_type) as sensor,
                value,
                FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', timestamp) as timestamp
            FROM {table_ref}
            WHERE
                device_id = @device_id
                AND timestamp BETWEEN @start_timestamp AND @end_timestamp
                AND LOWER(metric_type) IN ('temperature', 'humidity')
            ORDER BY timestamp ASC
        """
        job_config_data = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("device_id", "STRING", device_id),
                bigquery.ScalarQueryParameter("start_timestamp", "TIMESTAMP", start_timestamp),
                bigquery.ScalarQueryParameter("end_timestamp", "TIMESTAMP", end_timestamp)
            ]
        )
        
        query_job = client.query(data_query, job_config=job_config_data)
        results = [dict(row) for row in query_job]

        response_payload = {"displayDate": display_date_str, "readings": results}
        return (jsonify(response_payload), 200, headers)

    except Exception as e:
        print(f"Error al consultar BigQuery: {e}")
        error_payload = { "error": "Error en el servidor al consultar datos.", "details": str(e) }
        return (jsonify(error_payload), 500, headers)