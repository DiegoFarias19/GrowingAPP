-- Tabla USERS
CREATE TABLE `nombre_proyecto.dataset.USERS` (
  user_id STRING NOT NULL,
  name STRING,
  email STRING,
  sensor_assigned STRING,
  phone STRING,
  farm_assigned STRING,
  is_active BOOLEAN,
  CONSTRAINT pk_users PRIMARY KEY (user_id)
);

-- Tabla FARMS
CREATE TABLE `nombre_proyecto.dataset.FARMS` (
  farm_id STRING NOT NULL,
  name STRING,
  location GEOGRAPHY,
user_id STRING,
  CONSTRAINT pk_farms PRIMARY KEY (farm_id),
CONSTRAINT fk_farms_user FOREIGN KEY (user_id) REFERENCES `nombre_proyecto.dataset.USERS` (user_id)
);

-- Tabla CROPS
CREATE TABLE `nombre_proyecto.dataset.CROPS` (
  crop_id STRING NOT NULL,
  name STRING,
  map_px INT64,
  map_py INT64,
  climate_zone STRUCT<type STRING>,
  optimal_temp_min FLOAT64,
  optimal_temp_max FLOAT64,
  optimal_hum_min FLOAT64,
  optimal_hum_max FLOAT64,
  critical_temp_min FLOAT64,
  critical_temp_max FLOAT64,
  critical_hum_min FLOAT64,
  critical_hum_max FLOAT64,
  farm_id STRING,
  CONSTRAINT pk_crops PRIMARY KEY (crop_id),
  CONSTRAINT fk_crops_farm FOREIGN KEY (farm_id) REFERENCES `nombre_proyecto.dataset.FARMS` (farm_id)
);

-- Tabla DEVICES
CREATE TABLE `nombre_proyecto.dataset.DEVICES` (
  device_id STRING NOT NULL,
  crop_id STRING,
  CONSTRAINT pk_devices PRIMARY KEY (device_id),
  CONSTRAINT fk_devices_crop FOREIGN KEY (crop_id) REFERENCES `nombre_proyecto.dataset.CROPS` (crop_id)
);

-- Tabla SENSOR_READINGS
CREATE TABLE `nombre_proyecto.dataset.SENSOR_READINGS` (
  sensor_reading_id STRING NOT NULL,
  metric_type STRING,
  value FLOAT64,
  timestamp TIMESTAMP,
  device_id STRING,
  CONSTRAINT pk_sensor_readings PRIMARY KEY (sensor_reading_id),
  CONSTRAINT fk_sensor_device FOREIGN KEY (device_id) REFERENCES `nombre_proyecto.dataset.DEVICES` (device_id)
);

-- Tabla ACTUATOR_ACTIONS
CREATE TABLE `nombre_proyecto.dataset.ACTUATOR_ACTIONS` (
  actuator_action_id STRING NOT NULL,
  action BOOLEAN,
  timestamp TIMESTAMP,
  device_id STRING,
  CONSTRAINT pk_actuator_actions PRIMARY KEY (actuator_action_id),
  CONSTRAINT fk_actuator_device FOREIGN KEY (device_id) REFERENCES `nombre_proyecto.dataset.DEVICES` (device_id)
);

-- Tabla AI_RECOMMENDATIONS
CREATE TABLE `nombre_proyecto.dataset.AI_RECOMMENDATIONS` (
  ai_recommendation_id STRING NOT NULL,
  recommendation STRING,
  timestamp TIMESTAMP,
  climate_zone STRUCT<type STRING>,
  crop_id STRING,
  CONSTRAINT pk_ai_recommendations PRIMARY KEY (ai_recommendation_id),
  CONSTRAINT fk_ai_crop FOREIGN KEY (crop_id) REFERENCES `nombre_proyecto.dataset.CROPS` (crop_id)
);

-- Tabla ALERTS
CREATE TABLE `nombre_proyecto.dataset.ALERTS` (
  alert_id STRING NOT NULL,
  created_at TIMESTAMP,
  activation_time TIMESTAMP,
  description STRING,
  crop_id STRING,
  CONSTRAINT pk_alerts PRIMARY KEY (alert_id),
  CONSTRAINT fk_alerts_crop FOREIGN KEY (crop_id) REFERENCES `nombre_proyecto.dataset.CROPS` (crop_id)
);

-- Tabla SCHEDULED_ACTIONS
CREATE TABLE `nombre_proyecto.dataset.SCHEDULED_ACTIONS` (
  scheduled_id STRING NOT NULL,
  created_at TIMESTAMP,
  activation_time TIMESTAMP,
  device_id STRING,
  action BOOLEAN,
  crop_id STRING,
  CONSTRAINT pk_scheduled_actions PRIMARY KEY (scheduled_id),
  CONSTRAINT fk_sched_crop FOREIGN KEY (crop_id) REFERENCES `nombre_proyecto.dataset.CROPS` (crop_id),
  CONSTRAINT fk_sched_device FOREIGN KEY (device_id) REFERENCES `nombre_proyecto.dataset.DEVICES` (device_id)
);