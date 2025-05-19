import functions_framework
import requests
import os
from google.cloud import bigquery
from datetime import datetime, timezone

DEVICE_KEY = os.environ.get("DEVICE_KEY")
DEVICE_LOGIN_NAME = os.environ.get("DEVICE_LOGIN_NAME")
BIGQUERY_PROJECT_ID = os.environ.get("BIGQUERY_PROJECT_ID")
BIGQUERY_DATASET_ID = os.environ.get("BIGQUERY_DATASET_ID")
BIGQUERY_TABLE_ID = os.environ.get("BIGQUERY_TABLE_ID") 

PROPERTY_RELAY = "relay_Control"
PROPERTY_TEMP = "dht22_temperatura"
PROPERTY_HUMIDITY = "dht22_humedad"
ARDUINO_API_BASE_URL = "https://api2.arduino.cc/iot/v2/things"


bq_client = bigquery.Client(project=BIGQUERY_PROJECT_ID)

@functions_framework.http
def update_arduino_and_log(request):
    if not all([DEVICE_KEY, DEVICE_LOGIN_NAME, BIGQUERY_PROJECT_ID, BIGQUERY_DATASET_ID, BIGQUERY_TABLE_ID]):
        print("Error: Faltan variables de entorno requeridas.")
        return {
            "status": "error",
            "message": "Configuración incompleta en el servidor (faltan variables de entorno)."
        }, 500

    if request.method != 'POST':
        return {"status": "error", "message": "Método no permitido. Usar POST."}, 405

    try:
        data = request.get_json(silent=True)
        if data is None:
             return {"status": "error", "message": "Cuerpo de la petición vacío o no es JSON válido."}, 400

        temperature = data.get("temperature")
        humidity = data.get("humidity")
        relay_state = data.get("relay_state", None)

        if temperature is None or humidity is None:
            return {
                "status": "error",
                "message": "Faltan datos de 'temperature' o 'humidity' en el JSON."
                }, 400

        if not isinstance(temperature, (int, float)) or not isinstance(humidity, (int, float)):
             return {
                "status": "error",
                "message": "'temperature' y 'humidity' deben ser valores numéricos."
                }, 400

    except Exception as e:
        print(f"Error procesando la petición JSON: {e}")
        return {"status": "error", "message": f"Error procesando la petición: {str(e)}"}, 400

    headers = {
        "Authorization": f"Bearer {DEVICE_KEY}",
        "Content-Type": "application/json"
    }

    updates_to_perform = []
    timestamp_utc = datetime.now(timezone.utc)

    url_temp = f"{ARDUINO_API_BASE_URL}/{DEVICE_LOGIN_NAME}/properties/{PROPERTY_TEMP}/publish"
    payload_temp = {"value": temperature}
    updates_to_perform.append(("Temperatura", url_temp, payload_temp))

    url_humidity = f"{ARDUINO_API_BASE_URL}/{DEVICE_LOGIN_NAME}/properties/{PROPERTY_HUMIDITY}/publish"
    payload_humidity = {"value": humidity}
    updates_to_perform.append(("Humedad", url_humidity, payload_humidity))

    if relay_state is not None and isinstance(relay_state, bool):
        url_relay = f"{ARDUINO_API_BASE_URL}/{DEVICE_LOGIN_NAME}/properties/{PROPERTY_RELAY}/publish"
        payload_relay = {"value": relay_state}
        updates_to_perform.append(("Relé", url_relay, payload_relay))
    else:
        relay_state = None

    arduino_api_results = {}
    arduino_success = True
    for name, url, payload in updates_to_perform:
        try:
            response = requests.put(url, json=payload, headers=headers, timeout=10)
            response.raise_for_status()
            arduino_api_results[name] = {"status": "success", "response": response.status_code}
            print(f"Arduino API: {name} actualizado correctamente.")
        except requests.exceptions.RequestException as e:
            arduino_success = False
            error_message = f"Error al actualizar {name} en Arduino Cloud: {str(e)}"
            print(error_message)
            error_detail = None
            if hasattr(e, 'response') and e.response is not None:
                 try:
                    error_detail = e.response.json()
                 except ValueError:
                    error_detail = e.response.text
            arduino_api_results[name] = {"status": "error", "message": error_message, "details": error_detail}
            
    bq_errors = None
    try:
        table_ref = bq_client.dataset(BIGQUERY_DATASET_ID).table(BIGQUERY_TABLE_ID)
        row_to_insert = {
            "timestamp": timestamp_utc.isoformat(),
            "temperature": float(temperature),
            "humidity": float(humidity), 
            "relay_state": relay_state
        }
        if "relay_state" in [f.name for f in bq_client.get_table(table_ref).schema]:
             row_to_insert["relay_state"] = relay_state if relay_state is not None else None


        print(f"Intentando insertar en BigQuery: {row_to_insert}")
        bq_errors = bq_client.insert_rows_json(table_ref, [row_to_insert])

        if bq_errors == []:
            print("Datos insertados correctamente en BigQuery.")
        else:
            print(f"Errores al insertar en BigQuery: {bq_errors}")

    except Exception as e:
        print(f"Error general al interactuar con BigQuery: {e}")
        bq_errors = [{"message": f"Error de cliente BigQuery: {str(e)}"}]

    if arduino_success and not bq_errors:
        return {
            "status": "success",
            "message": "Datos actualizados en Arduino Cloud y guardados en BigQuery.",
            "arduino_results": arduino_api_results
        }, 200
    else:
        return {
            "status": "error",
            "message": "Ocurrieron errores durante el proceso.",
            "arduino_results": arduino_api_results,
            "bigquery_errors": bq_errors
        }, 500