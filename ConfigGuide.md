# WaterBee MQTT Configuration Guide
**WaterBee v4.8.0 Production Firmware - Remote Configuration via MQTT**

## Overview
WaterBee supports remote configuration via MQTT using a **3-topic strategy**. Each topic expects **complete JSON payloads** with all required fields, exactly matching the BLE configuration format.

## 📚 Quick Reference

| Topic | Purpose | Restart Required | Example Payload |
|-------|---------|------------------|-----------------|
| `v1/devices/me/net_conf` | WiFi & MQTT settings | ✅ Yes | `{"cred_data":{...},"server_data":{...}}` |
| `v1/devices/me/dev_cfg` | Device parameters | ✅ Yes | `{"deviceName":"...","measurementPeriod":180,...}` |
| `v1/devices/me/cal_data` | Sensor calibration | ❌ No | `{"calibrate_ph":{"low":null,"mid":7.0,"high":null}}` |
| `v1/devices/me/ts_req` | Request timestamp | ❌ No | `null` |
| `v1/devices/me/ts_res` | Receive timestamp | ❌ No | `{"timestamp":1735689600}` |

---

## 🌐 **Network Configuration**
**Topic**: `v1/devices/me/net_conf`  
**Purpose**: Configure WiFi credentials and MQTT broker settings  
**Restart Required**: ✅ Yes (3-second delay)

### Complete Network Configuration Template
```bash
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/net_conf \
  -m '{"cred_data":{"ssid":"RaspAP","password":"ChangeMe"},"server_data":{"mqttConfig":{"URI":"mqtt://plantomio.local","PORT":1883,"USERNAME":"plantomioX1","CLIENT_ID":"plantomioX1","MQTT_PASSWORD":"plantomioX1Pass","topic":"v1/devices/me/telemetry"}}}' \
  -u plantomioX1 -P plantomioX1Pass
```

### Production Network Configuration
```bash
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/net_conf \
  -m '{"cred_data":{"ssid":"ProductionWiFi","password":"SecurePass2024"},"server_data":{"mqttConfig":{"URI":"mqtts://secure-broker.com","PORT":8883,"USERNAME":"prod_user","CLIENT_ID":"waterBee_prod_001","MQTT_PASSWORD":"ProductionKey2024","topic":"v1/devices/me/telemetry"}}}' \
  -u plantomioX1 -P plantomioX1Pass
```

#### Required Fields
| Field | Type | Description |
|-------|------|-------------|
| `cred_data.ssid` | String | WiFi network name (max 31 chars) |
| `cred_data.password` | String | WiFi password (max 63 chars) |
| `server_data.mqttConfig.URI` | String | MQTT broker URL |
| `server_data.mqttConfig.PORT` | Number | MQTT broker port |
| `server_data.mqttConfig.USERNAME` | String | MQTT username |
| `server_data.mqttConfig.CLIENT_ID` | String | MQTT client identifier |
| `server_data.mqttConfig.MQTT_PASSWORD` | String | MQTT password |
| `server_data.mqttConfig.topic` | String | Telemetry publish topic |

---

## ⚙️ **Device Configuration**
**Topic**: `v1/devices/me/dev_cfg`  
**Purpose**: Configure measurement timing, device behavior, and radar settings  
**Restart Required**: ✅ Yes (3-second delay)

### Complete Device Configuration Template
```bash
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/dev_cfg \
  -m '{"deviceName":"waterBee","measurementPeriod":180,"sendingPeriod":900,"radarMode":"medium","tankHeight":"medium"}' \
  -u plantomioX1 -P plantomioX1Pass
```

### High-Frequency Monitoring
```bash
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/dev_cfg \
  -m '{"deviceName":"waterBee_lab","measurementPeriod":60,"sendingPeriod":300,"radarMode":"high","tankHeight":"small"}' \
  -u plantomioX1 -P plantomioX1Pass
```

### Power-Optimized Configuration
```bash
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/dev_cfg \
  -m '{"deviceName":"waterBee_remote","measurementPeriod":600,"sendingPeriod":3600,"radarMode":"low","tankHeight":"large"}' \
  -u plantomioX1 -P plantomioX1Pass
```

#### Required Fields (All Must Be Present)
| Field | Type | Valid Values | Description |
|-------|------|--------------|-------------|
| `deviceName` | String | Max 63 chars | Device identifier |
| `measurementPeriod` | Number | 10-172800 | Sensor reading interval (seconds) |
| `sendingPeriod` | Number | 10-172800 | Data transmission interval (seconds) |
| `radarMode` | String | `"low"`, `"medium"`, `"high"` | Distance sensor accuracy |
| `tankHeight` | String | `"small"`, `"medium"`, `"large"` | Tank size for level calculations |

---

## 🔬 **Calibration Data**
**Topic**: `v1/devices/me/cal_data`  
**Purpose**: Calibrate sensors individually (mirrors BLE workflow exactly)  
**Restart Required**: ❌ No (hot-reload)

### pH Calibration
```bash
# Mid Slot Calibration (pH 7.00 Buffer)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_ph":{"low":null,"mid":7.0,"high":null}}' \
  -u plantomioX1 -P plantomioX1Pass

# High slot Calibration (pH 4.01 and 7.00)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_ph":{"low":null,"mid":null,"high":10.1}}' \
  -u plantomioX1 -P plantomioX1Pass

# Low slot Calibration (pH 4.01)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_ph":{"low":4.01}}' \
  -u plantomioX1 -P plantomioX1Pass

# Clear a specific calibration point (use empty string)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_ph":{"low":"","mid":null,"high":""}}' \
  -u plantomioX1 -P plantomioX1Pass
```

### TDS Calibration
```bash
# Single Point Calibration (TDS 700 ppm)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_tds":{"low":null,"mid":700.0,"high":null}}' \
  -u plantomioX1 -P plantomioX1Pass

# Two Point Calibration (TDS 100 and 700 ppm)
# Three Point Calibration (TDS 100, 700, and 1500 ppm)
#serially for each slot separately, one by one only, when calibrating for low, all else should be null. 

# Clear all TDS calibration points
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_tds":{"low":"","mid":"","high":""}}' \
  -u plantomioX1 -P plantomioX1Pass
```

### ORP Calibration (Single Point Only)
```bash
# ORP 200 mV Standard Solution
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_orp":{"value":200.0}}' \
  -u plantomioX1 -P plantomioX1Pass

# ORP 475 mV Standard Solution
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_orp":{"value":475.0}}' \
  -u plantomioX1 -P plantomioX1Pass
```

### TDS-to-EC Conversion Factor
```bash
# Standard conversion factor (0.64)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"tds_to_ec_factor":0.64}' \
  -u plantomioX1 -P plantomioX1Pass

# Alternative conversion factor (0.50)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"tds_to_ec_factor":0.50}' \
  -u plantomioX1 -P plantomioX1Pass
```

### Distance/Fill Level Calibration
```bash
# Small tank (30cm empty to 3m full)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_fill":{"min_distance":0.3,"max_distance":3.0}}' \
  -u plantomioX1 -P plantomioX1Pass

# Large tank (50cm empty to 5m full)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_fill":{"min_distance":0.5,"max_distance":5.0}}' \
  -u plantomioX1 -P plantomioX1Pass
```

---

## ⏰ **Timestamp Synchronization**
**Purpose**: Sync device RTC with server time  
**Topics**: Request → `v1/devices/me/ts-req`, Response → `v1/devices/me/ts-res`

### Request Time Sync
```bash
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/ts-req \
  -m 'null' \
  -u plantomioX1 -P plantomioX1Pass
```

### Server Response Format
```bash
# Server should publish current Unix timestamp to v1/devices/me/ts-res
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/ts-res \
  -m '{"timestamp":1735689600}' \
  -u plantomioX1 -P plantomioX1Pass
```

---

## 📋 **Complete Configuration Workflow**

### Initial Device Setup
```bash
# 1. Configure network first
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/net_conf \
  -m '{"cred_data":{"ssid":"ProductionWiFi","password":"SecurePass2024"},"server_data":{"mqttConfig":{"URI":"mqtt://plantomio.local","PORT":1883,"USERNAME":"plantomioX1","CLIENT_ID":"waterBee_001","MQTT_PASSWORD":"plantomioX1Pass","topic":"v1/devices/me/telemetry"}}}' \
  -u plantomioX1 -P plantomioX1Pass

# 2. Wait for restart (5-10 seconds)

# 3. Configure device parameters
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/dev_cfg \
  -m '{"deviceName":"waterBee_001","measurementPeriod":180,"sendingPeriod":900,"radarMode":"medium","tankHeight":"medium"}' \
  -u plantomioX1 -P plantomioX1Pass

# 4. Wait for restart (5-10 seconds)

# 5. Calibrate sensors (no restart needed)
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/cal_data \
  -m '{"calibrate_ph":{"low":null,"mid":7.0,"high":null}}' \
  -u plantomioX1 -P plantomioX1Pass

# 6. Sync time
mosquitto_pub -h plantomio.local -p 1883 \
  -t v1/devices/me/ts-req \
  -m 'null' \
  -u plantomioX1 -P plantomioX1Pass
```

---

## 🔧 **Expected Device Responses**

### Successful Configuration
```
I (12345) MQTT_Broker_Handler: MQTT_EVENT_DATA: topic=v1/devices/me/dev_cfg, data_len=110
I (12345) mqtt_config: Processing device configuration update
I (12355) PERSISTENT_CFG: Successfully saved and verified to namespace: dev_cfg
I (12355) mqtt_config: Device configuration updated via MQTT
I (12355) mqtt_config: Scheduling restart in 3s: Device configuration updated
I (15355) mqtt_config: MQTT config restart timer triggered
```

### Successful Calibration
```
I (12345) MQTT_Broker_Handler: MQTT_EVENT_DATA: topic=v1/devices/me/cal_data, data_len=51
I (12345) mqtt_config: Processing calibration data update
I (12355) PERSISTENT_CFG: Successfully saved and verified to namespace: cal_data
I (12355) mqtt_config: Calibration data updated via MQTT
```

---

## ⚠️ **Important Rules**

1. **Complete JSON Objects**: Each calibration type must have ALL its fields (use `null` to preserve, `""` to clear)
2. **Slot-Based Calibration**: pH/TDS use low/mid/high slots, ORP uses single value
3. **No Automatic Clearing**: Existing calibration points are preserved unless explicitly cleared with `""`
4. **Multi-Point Support**: System automatically detects number of valid points and uses appropriate algorithm
5. **Hot-Reload**: Calibration changes take effect immediately without restart
6. **Exact Field Names**: Field names are case-sensitive and must match exactly
7. **Data Types**: Numbers without quotes, strings with quotes, `null` without quotes

---

**© 2025 WaterBee v4.8.1 - Clean MQTT Configuration Guide**