import functions_framework
import os
import uuid
from google.cloud import bigquery
from datetime import datetime, timezone
import json 
from pytz import timezone as pytz_timezone

DEVICE_LOGIN_NAME = os.environ.get("DEVICE_LOGIN_NAME") 
BIGQUERY_PROJECT_ID = os.environ.get("BIGQUERY_PROJECT_ID")
BIGQUERY_DATASET_ID = os.environ.get("BIGQUERY_DATASET_ID")
BIGQUERY_TABLE_ID = os.environ.get("BIGQUERY_TABLE_ID") 

bq_client = bigquery.Client(project=BIGQUERY_PROJECT_ID)

SANTIAGO_TZ = pytz_timezone('America/Santiago')

@functions_framework.http
def handle_incoming_sensor_data(request):
    print("--- Inicio de petición ---")
    
    try:
        if not all([BIGQUERY_PROJECT_ID, BIGQUERY_DATASET_ID, BIGQUERY_TABLE_ID]):
            print("Error: Faltan variables de entorno requeridas para BigQuery.")
            return {
                "status": "error",
                "message": "Configuración incompleta en el servidor (faltan variables de entorno de BigQuery)."
            }, 500

        if request.method != 'POST':
            print(f"Método no permitido: {request.method}. Se esperaba POST.")
            return {"status": "error", "message": "Método no permitido. Usar POST."}, 405

        data = None
        try:
            data = request.get_json(silent=False)
            print(f"Cuerpo de la petición parseado por get_json(): {data}")
        except Exception as e:
            print(f"Error al parsear el cuerpo de la petición como JSON con get_json(): {e}")
            try:
                raw_data = request.get_data(as_text=True)
                print(f"Cuerpo RAW de la petición recibido: {raw_data}")
                if raw_data:
                    data = json.loads(raw_data)
                    print(f"Cuerpo RAW parseado manualmente como JSON: {data}")
                else:
                    print("Cuerpo de la petición RAW está vacío.")
            except json.JSONDecodeError as e_json:
                print(f"Cuerpo RAW no es un JSON válido: {e_json}")
                return {"status": "error", "message": f"Cuerpo de la petición no es JSON válido: {e_json}"}, 400
            except Exception as e_raw:
                print(f"Error inesperado al leer cuerpo RAW: {e_raw}")
                return {"status": "error", "message": f"Error interno al procesar el cuerpo de la petición: {e_raw}"}, 500

        if data is None:
            print("Error: El cuerpo de la petición es nulo después de todos los intentos de parsing.")
            return {"status": "error", "message": "Cuerpo de la petición vacío o no es JSON válido."}, 400

        device_id = data.get("device_id") or data.get("thing_id", DEVICE_LOGIN_NAME) 
        event_timestamp_str = data.get("timestamp") or data.get("event_timestamp") 

        rows_to_insert = []
        insertion_errors = []

        if "values" in data and isinstance(data["values"], list):
            for item in data["values"]:
                metric_type = item.get("name")
                metric_value = item.get("value")
                
                item_timestamp_str = item.get("updated_at") or event_timestamp_str 
                
                final_timestamp_for_bq = None
                if item_timestamp_str:
                    try:
                        dt_utc = datetime.fromisoformat(item_timestamp_str.replace('Z', '+00:00'))
                        
                        dt_santiago = dt_utc.astimezone(SANTIAGO_TZ)
                        
                        final_timestamp_for_bq = dt_santiago.isoformat() 
                        
                    except ValueError:
                        print(f"Advertencia: Formato de timestamp '{item_timestamp_str}' no es ISO 8601 válido. Usando tiempo actual de Santiago.")
                        final_timestamp_for_bq = datetime.now(SANTIAGO_TZ).isoformat()
                else:
                    print("Advertencia: No se encontró timestamp en el payload. Usando tiempo actual de Santiago.")
                    final_timestamp_for_bq = datetime.now(SANTIAGO_TZ).isoformat()

                print(f"Procesando item: name={metric_type}, value={metric_value}, timestamp={final_timestamp_for_bq}")

                if metric_type is None or metric_value is None or not isinstance(metric_value, (int, float)):
                    print(f"Advertencia: Item incompleto o inválido, omitiendo: {item}")
                    continue 

                bq_metric_type = metric_type 
                if metric_type == "dht22_temperatura":
                    bq_metric_type = "temperature"
                elif metric_type == "dht22_humedad":
                    bq_metric_type = "humidity"

                formatted_value = round(float(metric_value), 1)

                row_to_insert = {
                    "sensor_reading_id": str(uuid.uuid4()), 
                    "device_id": device_id, 
                    "timestamp": final_timestamp_for_bq, # Usar el timestamp de Santiago
                    "metric_type": bq_metric_type, 
                    "value": formatted_value 
                }
                rows_to_insert.append(row_to_insert)

        else:
            print("Error: El payload no contiene un array 'values' válido. No hay datos para insertar.")
            return {"status": "error", "message": "Formato de payload inesperado. Falta el array 'values'."}, 400

        if rows_to_insert:
            try:
                table_ref = bq_client.dataset(BIGQUERY_DATASET_ID).table(BIGQUERY_TABLE_ID)
                print(f"Intentando insertar {len(rows_to_insert)} filas en BigQuery...")
                for row in rows_to_insert: 
                    print(f"  - Fila a insertar: {row}")
                
                bq_errors = bq_client.insert_rows_json(table_ref, rows_to_insert)

                if bq_errors == []:
                    print(f"{len(rows_to_insert)} datos insertados correctamente en BigQuery.")
                    return {
                        "status": "success",
                        "message": f"{len(rows_to_insert)} datos guardados en BigQuery."
                    }, 200
                else:
                    print(f"Errores al insertar en BigQuery: {bq_errors}")
                    insertion_errors.extend(bq_errors)
                    return {
                        "status": "error",
                        "message": "Ocurrieron errores al insertar datos en BigQuery.",
                        "bigquery_errors": insertion_errors
                    }, 500

            except Exception as e:
                print(f"Error general al interactuar con BigQuery: {e}")
                return {
                    "status": "error",
                    "message": f"Error interno al guardar datos en BigQuery: {str(e)}"
                }, 500
        else:
            print("No hay filas válidas para insertar en BigQuery.")
            return {"status": "warning", "message": "No se encontraron datos válidos en el payload para insertar en BigQuery."}, 200

    finally:
        print("--- Fin de petición ---")