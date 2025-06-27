import os
from google.cloud import bigquery
import requests
import json
from flask import Flask, request

app = Flask(__name__)

PROJECT_ID = "iot-growing-app"
DATASET_ID = "growing_app_bd"
SENSORS_TABLE_ID = "sensor_readings"
DEVICES_TABLE_ID = "devices"
CROPS_TABLE_ID = "crops"
RELAY_CONTROL_URL = "https://send-bool-acloud-712174296076.europe-west1.run.app"

client = bigquery.Client(project=PROJECT_ID)

@app.route('/', methods=['POST'])
def check_temperature_trigger():
    print("--- V5 --- Evento recibido, iniciando lógica de encendido/apagado ---")

    try:
        last_reading_query = f"""
            SELECT device_id, value
            FROM `{PROJECT_ID}.{DATASET_ID}.{SENSORS_TABLE_ID}`
            WHERE metric_type = 'temperature'
            ORDER BY timestamp DESC
            LIMIT 1
        """
        query_job = client.query(last_reading_query)
        last_reading = list(query_job)

        if not last_reading:
            print("No se encontraron lecturas de temperatura en la tabla.")
            return "Sin datos que procesar.", 200

        latest_data = last_reading[0]
        device_id = latest_data.device_id
        current_temp = float(latest_data.value)

        print(f"Última lectura encontrada: {current_temp}°C para el dispositivo {device_id}")

        crop_query = f"""
            SELECT c.critical_temp_min FROM `{PROJECT_ID}.{DATASET_ID}.{DEVICES_TABLE_ID}` d
            JOIN `{PROJECT_ID}.{DATASET_ID}.{CROPS_TABLE_ID}` c ON d.crop_id = c.crop_id
            WHERE d.device_id = @device_id
        """
        job_config = bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("device_id", "STRING", device_id)]
        )
        crop_result = list(client.query(crop_query, job_config=job_config))

        if crop_result and crop_result[0].critical_temp_min is not None:
            critical_temp = float(crop_result[0].critical_temp_min)
            print(f"DEBUG: Temp Actual: {current_temp}°C, Temp Crítica: {critical_temp}°C")

            if current_temp > critical_temp:
                print(f"¡ALERTA! Temperatura supera el umbral. Activando relé.")
                response = requests.post(RELAY_CONTROL_URL, json={"state": True}, timeout=10)
                response.raise_for_status()
                print("Solicitud para ACTIVAR el relé enviada con éxito.")
            else:
                print("Temperatura dentro de los límites. Apagando relé.")
                print("Solicitud para APAGAR el relé enviada con éxito.")
        else:
            print(f"No se encontró temperatura crítica para el dispositivo {device_id}.")

    except Exception as e:
        print(f"Error inesperado durante el procesamiento: {e}")
        return "Error interno en el servidor.", 500

    return "Procesamiento completado con éxito.", 200

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))