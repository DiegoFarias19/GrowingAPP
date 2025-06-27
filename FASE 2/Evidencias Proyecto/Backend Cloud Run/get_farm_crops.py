import functions_framework
import json
from google.cloud import bigquery
import os
# import uuid # No se usa en esta función, puedes quitarlo si no es necesario globalmente

@functions_framework.http
def get_farm_crops_http(request):
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
        if not current_project_id or not current_dataset_id: # Simplificada la comprobación del cliente
            raise ValueError("Configuración de BigQuery incompleta (PROJECT_ID o DATASET_ID no encontrados en el entorno).")
    except Exception as e:
        print(f"ERROR: Error de configuración de BigQuery en get_farm_crops_http: {e}")
        return (json.dumps({"error": "Error de configuración del servidor", "details": str(e)}), 500, headers)

    farm_id = request.args.get('farm_id')
    if not farm_id:
        return (json.dumps({"error": "Falta el parámetro 'farm_id' en la URL"}), 400, headers)

    query = f"""
        SELECT
            crop_id AS id,
            farm_id, 
            crop_name AS name,
            IFNULL(image_url, 'assets/images/farm_default.png') AS imageUrl,
            status
        FROM
            `{current_project_id}.{current_dataset_id}.crops`
        WHERE
            farm_id = @farm_id
        ORDER BY
            name;
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("farm_id", "STRING", farm_id)
        ]
    )

    try:
        print(f"Ejecutando consulta de cultivos para farm_id: {farm_id}")
        query_job = current_bq_client.query(query, job_config=job_config)
        results = query_job.result()

        processed_crops = []
        for row in results:
            
            current_crop_id_value = None
            if row.id is not None: 
                current_crop_id_value = str(row.id)
            else:
                current_crop_id_value = f"error_crop_id_is_null_for_farm_{farm_id}" 

            current_crop_name_value = None
            if row.name is not None: 
                current_crop_name_value = str(row.name) 
            else:
                current_crop_name_value = "Cultivo sin Nombre"
            
            processed_crops.append({
                "crop_id": current_crop_id_value,
                "farm_id": str(row.farm_id) if row.farm_id is not None else None,
                "crop_name": current_crop_name_value,
                "image_url": str(row.imageUrl),
                "status": str(row.status) if row.status is not None else None
            })
        
        print(f"Cultivos encontrados para farm_id {farm_id}: {len(processed_crops)}")
        return (json.dumps(processed_crops), 200, headers)
    except Exception as e:
        print(f"Error al consultar o procesar cultivos para farm_id {farm_id}: {e}")
        return (json.dumps({"error": "Error interno al obtener cultivos", "details": str(e)}), 500, headers)