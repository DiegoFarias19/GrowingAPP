import functions_framework
import json
from google.cloud import bigquery
import os
import uuid

try:
    PROJECT_ID = os.environ['BIGQUERY_PROJECT_ID'] 
    DATASET_ID = os.environ['BIGQUERY_DATASET_ID'] 
    BQ_CLIENT = bigquery.Client(project=PROJECT_ID) 
    print(f"BigQuery Client inicializado para proyecto {PROJECT_ID} y dataset {DATASET_ID}")
except KeyError as e:
    print(f"CRITICAL: Variable de entorno {e} no encontrada.")
    raise RuntimeError(f"Configuración de entorno incompleta: falta {e}") from e
except Exception as e:
    print(f"CRITICAL: Error inicializando BigQuery Client globalmente: {e}")
    raise RuntimeError(f"No se pudo inicializar BigQuery Client: {e}") from e

@functions_framework.http
def create_farm_http(request):
    """HTTP Cloud Function para crear una nueva granja.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text, or any set of values flask.Response can accept.
    """
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS', 
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '3600'
    }

    if request.method == 'OPTIONS':
        return ('', 204, headers) 
    
    if request.method != 'POST':
        return (json.dumps({"error": "Método no permitido, se espera POST"}), 405, headers)

    user_uid_param = request.args.get('user_uid') 
    if not user_uid_param: 
        return (json.dumps({"error": "Falta el parámetro 'user_uid' en la URL o token de autorización"}), 400, headers)
    user_uid_to_create_for = user_uid_param
    print(f"Usando user_uid del parámetro de URL: {user_uid_to_create_for}")

    try:
        data = request.get_json(silent=True) 
        if data is None: 
             return (json.dumps({"error": "Cuerpo de la solicitud no es JSON válido o está vacío"}), 400, headers)
        if 'farm_name' not in data or not data['farm_name'].strip(): 
            return (json.dumps({"error": "Falta 'farm_name' o está vacío en el cuerpo JSON de la solicitud"}), 400, headers)
    except Exception as e: 
        print(f"Error parseando JSON en create_farm: {e}")
        return (json.dumps({"error": "Cuerpo JSON inválido", "details": str(e)}), 400, headers)
        
    db_farm_name = data['farm_name'].strip()
    image_url = data.get('image_url') 
    location = data.get('location')   
    description = data.get('description') 
    
    status_from_request = data.get('status')
    status_boolean = True

    if status_from_request is not None:
        if isinstance(status_from_request, bool):
            status_boolean = status_from_request
        elif isinstance(status_from_request, str):
            if status_from_request.lower() in ['true', 'active', '1']:
                status_boolean = True
            elif status_from_request.lower() in ['false', 'inactive', '0']:
                status_boolean = False
            else:
                print(f"Valor de status no reconocido '{status_from_request}', usando default True.")
        else:
            print(f"Tipo de status no esperado '{type(status_from_request)}', usando default True.")
    
    new_farm_id = str(uuid.uuid4())

    rows_to_insert = [{
        "farm_id": new_farm_id,
        "user_uid": user_uid_to_create_for, 
        "farm_name": db_farm_name,
        "image_url": image_url,
        "location": location,
        "description": description, 
        "status": status_boolean,
    }]
    
    table_ref = BQ_CLIENT.dataset(DATASET_ID).table('farms') 
    try:
        print(f"Intentando insertar nueva granja: ID={new_farm_id}, Usuario={user_uid_to_create_for}, Nombre='{db_farm_name}', Status={status_boolean}")
        errors = BQ_CLIENT.insert_rows_json(table_ref, rows_to_insert) 
        
        if not errors:
            response_data = {
                "farm_id": new_farm_id,            
                "farm_name": db_farm_name,         
                "image_url": image_url,            
                "location": location,
                "description": description,
                "status": status_boolean,
                "user_uid": user_uid_to_create_for 
            }
            print(f"Nueva granja creada exitosamente: {new_farm_id}. Respuesta: {response_data}")
            return (json.dumps(response_data), 201, headers)
        else:
            print(f"Errores al insertar nueva granja {new_farm_id} en BigQuery: {errors}")
            error_details_str = str(errors)
            if len(error_details_str) > 500:
                 error_details_str = error_details_str[:500] + "..."
            return (json.dumps({
                "error": "No se pudo crear la granja en la base de datos.", 
                "details": error_details_str
            }), 500, headers)
            
    except Exception as e:
        print(f"Excepción crítica al insertar en BigQuery para granja {new_farm_id}: {e}")
        return (json.dumps({
            "error": "Error interno del servidor al intentar crear la granja.",
            "details": "Se ha producido un error inesperado."
        }), 500, headers)