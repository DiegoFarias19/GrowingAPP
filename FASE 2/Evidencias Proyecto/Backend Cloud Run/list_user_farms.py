import functions_framework
import json
from google.cloud import bigquery
import os
import uuid
try:
    bq_client = bigquery.Client()
    PROJECT_ID = os.environ.get('BIGQUERY_PROJECT_ID')
    DATASET_ID = os.environ.get('BIGQUERY_DATASET_ID')
except Exception as e:
    print(f"CRITICAL: Error inicializando BigQuery Client: {e}")
    bq_client = None
def format_bigquery_rows(rows):
    return [dict(row) for row in rows]

@functions_framework.http
def get_user_farms_http(request):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '3600'
    }

    if request.method == 'OPTIONS':
        return ('', 204, headers)

    if not bq_client or not PROJECT_ID or not DATASET_ID:
        return (json.dumps({"error": "Configuración de backend incompleta..."}), 500, headers)


    user_uid = request.args.get('user_uid')
    if not user_uid:
        return (json.dumps({"error": "Falta el parámetro 'user_uid' en la URL"}), 400, headers)
    
    user_uid_to_query = user_uid

    query = f"""
        SELECT farm_id, farm_name, IFNULL(image_url, 'assets/images/farm_default.png') as imageUrl
        FROM `{PROJECT_ID}.{DATASET_ID}.farms`
        WHERE user_uid = @user_uid ORDER BY farm_name;
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[bigquery.ScalarQueryParameter("user_uid", "STRING", user_uid_to_query)]
    )

    try:
        query_job = bq_client.query(query, job_config=job_config)
        results = query_job.result()
        farms_data = format_bigquery_rows(results)
        return (json.dumps(farms_data), 200, headers)
    except Exception as e:
        return (json.dumps({"error": "Error interno...", "details": str(e)}), 500, headers)