import os
import requests
import json
import functions_framework

ARDUINO_CLIENT_ID = os.environ.get('ARDUINO_CLIENT_ID', 'xD2qyoOLqut2tRG8tuwOIYdeVJb3uJsS')
ARDUINO_CLIENT_SECRET = os.environ.get('ARDUINO_CLIENT_SECRET', 'l7tvmbeBBjHYrusPpCUf6sa3RKlaauWoSmpW4HofGlvO4E5gx2OORfIWE83BEHuO')
ARDUINO_THING_ID = os.environ.get('ARDUINO_THING_ID', '5be76a70-5435-4f31-94c4-62a8d73c75f2')
ARDUINO_PROPERTY_ID = os.environ.get('ARDUINO_PROPERTY_ID', 'relay_Control')

ARDUINO_TOKEN_URL = "https://api2.arduino.cc/iot/v1/clients/token"
ARDUINO_API_BASE_URL = "https://api2.arduino.cc/iot/v2/things"

def get_arduino_access_token():
    """Obtiene un token de acceso OAuth2 para la API de Arduino Cloud."""
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {
        'grant_type': 'client_credentials',
        'client_id': ARDUINO_CLIENT_ID,
        'client_secret': ARDUINO_CLIENT_SECRET,
        'audience': 'https://api2.arduino.cc/iot'
    }
    try:
        response = requests.post(ARDUINO_TOKEN_URL, headers=headers, data=data)
        response.raise_for_status()
        return response.json().get('access_token')
    except requests.exceptions.RequestException as e:
        print(f"Error al obtener el token de Arduino Cloud: {e}")
        return None

def update_arduino_thing_property(access_token, thing_id, property_id, new_value):
    """Actualiza una propiedad (variable) de un Thing en Arduino Cloud."""
    if not access_token:
        return False, "No se pudo obtener el token de acceso."

    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    payload = {"value": new_value}
    url = f"{ARDUINO_API_BASE_URL}/{thing_id}/properties/{property_id}/publish"

    try:
        response = requests.put(url, headers=headers, json=payload)
        response.raise_for_status()
        print(f"Propiedad '{property_id}' actualizada a {new_value} en Thing '{thing_id}'")
        return True, "Propiedad actualizada exitosamente."
    except requests.exceptions.RequestException as e:
        print(f"Error de API al actualizar la propiedad: {e.response.status_code} - {e.response.text if e.response else 'No response'}")
        return False, f"Error en API Arduino ({e.response.status_code if e.response else 'N/A'}): {e.response.text if e.response else str(e)}"


@functions_framework.http
def send_bool_to_arduino(request):

    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    headers = {
        'Access-Control-Allow-Origin': '*'
    }
    if request.method != 'POST':
        return ('Solo se permiten solicitudes POST', 405, headers)

    request_json = request.get_json(silent=True)
    if not request_json or 'state' not in request_json:
        return (json.dumps({'status': 'error', 'message': 'Falta el cuerpo JSON con la clave "state".'}), 400, headers)

    relay_state = request_json.get('state')
    if not isinstance(relay_state, bool):
        return (json.dumps({'status': 'error', 'message': 'El valor de "state" debe ser un booleano (true/false).'}), 400, headers)

    print(f"Recibido estado para el relé: {relay_state}")

    access_token = get_arduino_access_token()
    if not access_token:
        return (json.dumps({'status': 'error', 'message': 'Error interno: No se pudo obtener el token de Arduino.'}), 500, headers)

    success, message = update_arduino_thing_property(
        access_token,
        ARDUINO_THING_ID,
        ARDUINO_PROPERTY_ID,
        relay_state
    )

    if success:
        response_payload = {"status": "success", "message": message, "new_relay_state": relay_state}
        return (json.dumps(response_payload), 200, headers)
    else:
        response_payload = {"status": "error", "message": message}
        return (json.dumps(response_payload), 500, headers)