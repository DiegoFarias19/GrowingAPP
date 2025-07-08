import os
import json
from google.cloud import bigquery
import functions_framework

# --- Configuración ---
PROJECT_ID = os.environ.get("GCP_PROJECT", "iot-growing-app")
DATASET_ID = "growing_app_bd"
DEVICES_TABLE_ID = "devices"

client = bigquery.Client()

@functions_framework.http
def get_device_state(request):
    """
    Función HTTP que devuelve el estado actual (relay y modo) de un dispositivo.
    Espera un 'device_id' como parámetro en la URL (query string).
    """
    # --- Manejo de CORS ---
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
    }
    if request.method == 'OPTIONS':
        return ('', 204, headers)

    # --- Lógica principal ---
    device_id = request.args.get('device_id')
    if not device_id:
        response_data = {'status': 'error', 'message': 'El parámetro "device_id" es requerido en la URL.'}
        return (json.dumps(response_data), 400, headers)

    print(f"Buscando estado para el dispositivo: {device_id}")

    try:
        query = f"""
            SELECT state, control_mode
            FROM `{PROJECT_ID}.{DATASET_ID}.{DEVICES_TABLE_ID}`
            WHERE device_id = @device_id
            LIMIT 1
        """
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("device_id", "STRING", device_id),
            ]
        )
        query_job = client.query(query, job_config=job_config)
        results = list(query_job)

        if not results:
            response_data = {'status': 'error', 'message': 'Dispositivo no encontrado.'}
            return (json.dumps(response_data), 404, headers)

        device_data = results[0]
        # Asegurarse de que los valores nulos se manejen correctamente
        relay_state = device_data.state if device_data.state is not None else False
        control_mode = device_data.control_mode if device_data.control_mode is not None else 'MANUAL'

        response_data = {
            'status': 'success',
            'relay_state': relay_state,
            'control_mode': control_mode
        }
        return (json.dumps(response_data), 200, headers)

    except Exception as e:
        print(f"Error inesperado: {e}")
        response_data = {'status': 'error', 'message': 'Error interno del servidor.'}
        return (json.dumps(response_data), 500, headers)