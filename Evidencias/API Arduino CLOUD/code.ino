#include <ArduinoIoTCloud.h>
#include <Arduino_ConnectionHandler.h>
#include <DHT.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <time.h>

#define DHTPIN 14
#define DHTTYPE DHT22
#define RELAY_PIN 4

DHT dht(DHTPIN, DHTTYPE);

const char DEVICE_LOGIN_NAME[]  = SECRET_DEVICE_LOGIN;
const char SSID[]               = SECRET_SSID;
const char PASS[]               = SECRET PASS;
const char DEVICE_KEY[]         = SECRET_DEVICE_KEY;

CloudTemperatureSensor dht22_temperatura;
CloudRelativeHumidity dht22_humedad;
CloudSwitch relay_Control;
CloudSwitch relay_Status;

const char* gcp_url = SECRET_GCP_URL;

unsigned long lastUpdate = 0;
const unsigned long updateInterval = 60000;

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
                       String("\", \"sensor_type\": \"") + sensor_type +
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
  }
  http.end();
}

void onRelayControlChange() {
  digitalWrite(RELAY_PIN, relay_Control ? HIGH : LOW);
  relay_Status = relay_Control;
}

void initProperties() {
  ArduinoCloud.setBoardId(DEVICE_LOGIN_NAME);
  ArduinoCloud.setSecretDeviceKey(DEVICE_KEY);

  ArduinoCloud.addProperty(dht22_temperatura, READ, 60 * SECONDS, NULL);
  ArduinoCloud.addProperty(dht22_humedad, READ, 60 * SECONDS, NULL);
  ArduinoCloud.addProperty(relay_Control, READWRITE, ON_CHANGE, onRelayControlChange);
  ArduinoCloud.addProperty(relay_Status, READ, ON_CHANGE, NULL);
}

WiFiConnectionHandler ArduinoIoTPreferredConnection(SSID, PASS);

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
