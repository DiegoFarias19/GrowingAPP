#include <ArduinoIoTCloud.h>
#include <Arduino_ConnectionHandler.h>
#include <DHT.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <time.h>
#include <ArduinoJson.h> 

#define DHTPIN 14
#define DHTTYPE DHT22
#define RELAY_PIN 4

DHT dht(DHTPIN, DHTTYPE);

const char DEVICE_LOGIN_NAME[]  = SECRET_LOGIN;
const char SSID[]               = SECRET_SSID;
const char PASS[]               = SECRET_PASS;
const char DEVICE_KEY[]         = SECRET_DEVICE_KEY;

CloudTemperatureSensor dht22_temperatura;
CloudRelativeHumidity dht22_humedad;
CloudSwitch relay_Control;
CloudSwitch relay_Status;

const char* gcp_url = SECRET_GCP_URL;

unsigned long lastUpdate = 0;
const unsigned long updateInterval = 15000;

String getDeviceId() {
  return WiFi.macAddress();
}

void sendSensorDataToGCP(const char* sensor_type, float value) {
  HTTPClient http;
  http.begin(gcp_url);
  http.addHeader("Content-Type", "application/json");

  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Error al obtener la hora");
    http.end();
    return;
  }
  char timestamp[25];
  strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);

  String device_id = getDeviceId();

  String jsonPayload = String("{\"device_id\": \"") + device_id +
                     String("\", \"metric_type\": \"") + sensor_type +
                     String("\", \"value\": ") + String(value, 2) +
                     String(", \"timestamp\": \"") + String(timestamp) + String("\"}");

  Serial.print("Payload JSON enviado: ");
  Serial.println(jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    Serial.print("Código HTTP recibido de GCP: ");
    Serial.println(httpResponseCode);
    if (httpResponseCode == 200) {
      Serial.println("Datos enviados correctamente a GCP");
    } else {
      Serial.println("Error en la respuesta de GCP");
      String response = http.getString();
      Serial.print("Respuesta GCP: ");
      Serial.println(response);
    }
  } else {
    Serial.println("Error al enviar datos a GCP");
    Serial.println(http.errorToString(httpResponseCode));
  }
  http.end();
}

void onRelayControlChange() {
  Serial.print("relay_Control cambió a: ");
  Serial.println(relay_Control ? "true (ENCENDIDO)" : "false (APAGADO)");

  // Accionar el relé según el valor de relay_Control
  if (relay_Control) {
    digitalWrite(RELAY_PIN, HIGH); // Enciende el relé
    Serial.println("Relé ENCENDIDO");
  } else {
    digitalWrite(RELAY_PIN, LOW);  // Apaga el relé
    Serial.println("Relé APAGADO");
  }

  // Actualizar el estado de 'relay_Status' para que Arduino Cloud refleje el estado real
  relay_Status = relay_Control;
}

void initProperties() {
  ArduinoCloud.setBoardId(DEVICE_LOGIN_NAME);
  ArduinoCloud.setSecretDeviceKey(DEVICE_KEY);

  ArduinoCloud.addProperty(dht22_temperatura, READ, 15 * SECONDS, NULL);
  ArduinoCloud.addProperty(dht22_humedad, READ, 15 * SECONDS, NULL);
  ArduinoCloud.addProperty(relay_Control, READWRITE, ON_CHANGE, onRelayControlChange);
  ArduinoCloud.addProperty(relay_Status, READ, ON_CHANGE, NULL);
}

WiFiConnectionHandler ArduinoIoTPreferredConnection(SSID, PASS);


bool consultarEstadoDesdeBackend() {
  HTTPClient http;
  http.begin(gcp_url);

  int httpCode = http.GET();
  if (httpCode == 200) {
    String payload = http.getString();
    Serial.println("Respuesta del backend: " + payload);

    // Parsear JSON
    StaticJsonDocument<200> doc;
    DeserializationError error = deserializeJson(doc, payload);

    if (error) {
      Serial.print("Error parseando JSON: ");
      Serial.println(error.c_str());
      http.end();
      return relay_Control;  // mantener estado actual si hay error
    }

    bool relayStatusFromBackend = doc["relay_status"];
    http.end();
    return relayStatusFromBackend;
  } else {
    Serial.print("Error al consultar el backend. Código: ");
    Serial.println(httpCode);
    http.end();
    return relay_Control;  // mantener estado actual si hay error
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  pinMode(RELAY_PIN, OUTPUT);
  initProperties();
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);

  WiFi.begin(SSID, PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado");

  configTime(0, 0, "pool.ntp.org", "time.google.com");

int retries = 0;
const int maxRetries = 10;

struct tm timeinfo;
while (!getLocalTime(&timeinfo) && retries < maxRetries) {
  Serial.println("Esperando tiempo NTP...");
  retries++;
  delay(1000);
}

if (retries == maxRetries) {
  Serial.println("No se pudo obtener la hora NTP. Continuando sin timestamp.");
} else {
  Serial.println("Hora NTP obtenida correctamente.");
}

  onRelayControlChange();
}

void loop() {
  ArduinoCloud.update();

  unsigned long currentMillis = millis();

  if (currentMillis - lastUpdate >= updateInterval) {
    lastUpdate = currentMillis;

    float temp = dht.readTemperature();
    float hum = dht.readHumidity();

    if (!isnan(temp)) {
      sendSensorDataToGCP("DHT22_Temperature", temp);
      dht22_temperatura = temp;
    } else {
      Serial.println("Error al leer la temperatura del sensor DHT22!");
    }

    if (!isnan(hum)) {
      sendSensorDataToGCP("DHT22_Humidity", hum);
      dht22_humedad = hum;
    } else {
      Serial.println("Error al leer la humedad del sensor DHT22!");
    }

    relay_Status = digitalRead(RELAY_PIN);

    Serial.print("Temperatura: ");
    Serial.print(dht22_temperatura);
    Serial.print(" °C, Humedad: ");
    Serial.print(dht22_humedad);
    Serial.println(" %");

    Serial.print("Estado del Relé: ");
    Serial.println(relay_Status == HIGH ? "ENCENDIDO" : "APAGADO");

    Serial.println("Loop ejecutándose...");
  }
}