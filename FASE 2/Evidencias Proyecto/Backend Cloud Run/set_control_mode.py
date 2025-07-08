import os
import json
from google.cloud import bigquery
import functions_framework

# --- Configuración ---
# El project ID se obtiene automáticamente del entorno de ejecución de GCP.
PROJECT_ID = os.environ.get("GCP_PROJECT", "iot-growing-app")
DATASET_ID = os.environ.get("GCP_DATASET", "growing-app-bd")
DEVICES_TABLE_ID = "devices"

# Se inicializa el cliente de BigQuery una sola vez de forma global.
client = bigquery.Client()

@functions_framework.http
def set_control_mode(request):
    """
    Función HTTP de Cloud Functions para actualizar el modo de control de un dispositivo.
    Responde a solicitudes POST con un cuerpo JSON.
    """
    # --- Manejo de CORS (Cross-Origin Resource Sharing) ---
    # Estas cabeceras son necesarias para permitir que tu app Flutter (que se ejecuta
    # en un navegador o webview) pueda llamar a esta función.
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '3600'
    }

    # El navegador envía una solicitud "preflight" de tipo OPTIONS antes de la solicitud POST
    # para verificar los permisos de CORS. Respondemos con éxito.
    if request.method == 'OPTIONS':
        return ('', 204, headers)

    # Para la respuesta principal, solo se necesita la cabecera de origen.
    headers = {'Access-Control-Allow-Origin': '*'}

    # --- Lógica principal de la función ---
    if request.method != 'POST':
        response_data = {'status': 'error', 'message': 'Solo se permiten solicitudes POST'}
        return (json.dumps(response_data), 405, headers)

    try:
        data = request.get_json(silent=True)
        if not data or 'device_id' not in data or 'control_mode' not in data:
            response_data = {'status': 'error', 'message': 'Faltan "device_id" o "control_mode" en el cuerpo de la solicitud.'}
            return (json.dumps(response_data), 400, headers)

        device_id = data['device_id']
        mode = data['control_mode']

        if mode not in ['AUTOMATICO', 'MANUAL']:
            response_data = {'status': 'error', 'message': 'El valor de "control_mode" debe ser "AUTOMATICO" o "MANUAL".'}
            return (json.dumps(response_data), 400, headers)

        print(f"Actualizando modo para el dispositivo {device_id} a '{mode}'")

        # Se construye y ejecuta la consulta para actualizar el modo en BigQuery.
        update_query = f"""
            UPDATE `{PROJECT_ID}.{DATASET_ID}.{DEVICES_TABLE_ID}`
            SET control_mode = @mode
            WHERE device_id = @device_id
        """
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("mode", "STRING", mode),
                bigquery.ScalarQueryParameter("device_id", "STRING", device_id),
            ]
        )
        query_job = client.query(update_query, job_config=job_config)
        query_job.result()  # Se espera a que la consulta termine.

        if query_job.num_dml_affected_rows > 0:
            print(f"Éxito: {query_job.num_dml_affected_rows} fila(s) actualizada(s).")
            response_data = {'status': 'success', 'message': f'Modo actualizado a {mode}'}
            return (json.dumps(response_data), 200, headers)
        else:
            print(f"Advertencia: No se encontró ningún dispositivo con el ID {device_id} para actualizar.")
            response_data = {'status': 'error', 'message': 'Dispositivo no encontrado.'}
            return (json.dumps(response_data), 404, headers)

    except Exception as e:
        print(f"Error inesperado: {e}")
        response_data = {'status': 'error', 'message': 'Error interno del servidor.'}
        return (json.dumps(response_data), 500, headers)