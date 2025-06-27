import functions_framework
import json
from google.cloud import bigquery
import os

@functions_framework.http
def get_crop_devices_http(request):
    """HTTP Cloud Function para obtener los dispositivos de un cultivo."""
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '3600'
    }

    if request.method == 'OPTIONS':
        return ('', 204, headers)

    try:
        current_bq_client = bigquery.Client()
        current_project_id = os.environ.get('BIGQUERY_PROJECT_ID')
        current_dataset_id = os.environ.get('BIGQUERY_DATASET_ID')
        if not current_project_id or not current_dataset_id:
            raise ValueError("Configuración de BigQuery incompleta (PROJECT_ID o DATASET_ID no encontrados en el entorno).")
    except Exception as e:
        print(f"ERROR: Error de configuración de BigQuery en get_crop_devices_http: {e}")
        return (json.dumps({"error": "Error de configuración del servidor", "details": str(e)}), 500, headers)

    crop_id = request.args.get('crop_id')
    if not crop_id:
        return (json.dumps({"error": "Falta el parámetro 'crop_id' en la URL"}), 400, headers)

    query = f"""
    SELECT
        device_id AS id,
        crop_id,
        device_name AS name,
        state
    FROM
        `{current_project_id}.{current_dataset_id}.devices`
    WHERE
        crop_id = @crop_id
    ORDER BY
        name;
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("crop_id", "STRING", crop_id)
        ]
    )

    try:
        print(f"Ejecutando consulta de dispositivos para crop_id: {crop_id}")
        query_job = current_bq_client.query(query, job_config=job_config)
        results = query_job.result()

        processed_devices = []
        for row in results:
            processed_devices.append({
            "device_id": str(row.id) if row.id is not None else None,
            "crop_id": str(row.crop_id) if row.crop_id is not None else None,
            "device_name": str(row.name) if row.name is not None else "Dispositivo sin Nombre",
            "state": bool(row.state) if row.state is not None else None 
        })

        print(f"Dispositivos encontrados para crop_id {crop_id}: {len(processed_devices)}")
        return (json.dumps(processed_devices), 200, headers)
    except Exception as e:
        print(f"Error al consultar o procesar dispositivos para crop_id {crop_id}: {e}")
        return (json.dumps({"error": "Error interno al obtener dispositivos", "details": str(e)}), 500, headers)