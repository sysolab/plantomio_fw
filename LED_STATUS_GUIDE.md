# WaterBee V4.8 LED Status Guide

## 🔍 LED Pattern Decoder for Users

This comprehensive guide explains all LED patterns and what they mean for your WaterBee water quality monitoring system. The RGB LED provides instant visual feedback about system status, operations, and any issues that need attention.

---

## 📋 Quick Reference Card

| **Color** | **Pattern** | **Meaning** | **Action Required** |
|-----------|-------------|-------------|-------------------|
| 🔵 Blue | Breathing | System booting/connecting | Wait |
| ⚫ Off | No light | System ready/idle | Normal operation |
| 🔴 Red | Solid | Measuring water quality | Wait for completion |
| 🔵 Blue | Solid | Processing data | Wait |
| 🔷 Cyan | Flash | Transmitting data | Normal operation |
| 🔴 Red | Double flash | Error detected | Check system |
| 🟣 Purple | Pulse | Calibration mode | Follow prompts |
| 🟡 Yellow | Flash | Warning/config change | Check status |
| ⚪ White | Flash | Button acknowledged | Normal operation |

---

## 🎯 System State Indicators

### **Boot & Initialization**

#### 🔵 **Blue Breathing** - System Starting
- **When**: Power on, system restart
- **Pattern**: Slow, smooth blue fade in/out (breathing effect)
- **Duration**: 5-15 seconds during startup
- **Meaning**: WaterBee is booting up and initializing
- **Action**: Wait for system to complete startup

#### ⚪ **White Flash** - Sensor Initialization
- **When**: During system startup
- **Pattern**: Brief white flash (150ms)
- **Meaning**: Sensors are being initialized
- **Action**: Normal startup process

---

### **Normal Operation**

#### ⚫ **LED Off** - Ready & Idle
- **When**: System fully operational and waiting between measurements
- **Pattern**: No LED indication (completely off)
- **Meaning**: System is healthy, ready, and conserving power
- **Action**: None - system is ready for use (press button for immediate measurement)

#### 🔴 **Red Solid** - Measuring
- **When**: Taking water quality measurements
- **Pattern**: Solid red light (continuous)
- **Duration**: 2-8 seconds per measurement cycle
- **Meaning**: pH, TDS, temperature, and distance sensors active
- **Action**: Keep sensors undisturbed in water

#### 🔵 **Blue Solid** - Processing Data
- **When**: After measurement completion
- **Pattern**: Solid blue light
- **Duration**: 1-2 seconds
- **Meaning**: Calculating and processing sensor data
- **Action**: Wait for processing to complete

#### 🔷 **Cyan Flash** - Transmitting Data
- **When**: Sending data via WiFi/MQTT
- **Pattern**: Brief cyan flash (400ms)
- **Meaning**: Successfully transmitting measurement data
- **Action**: None - normal data transmission

---

### **User Interaction**

#### ⚪ **White Flash** - Button Press Acknowledged
- **When**: Immediately after pressing the button
- **Pattern**: Quick white flash (100ms)
- **Meaning**: Button press received, starting immediate measurement
- **Action**: Wait for measurement to begin

#### 🟣 **Purple Pulse** - Calibration Mode
- **When**: Calibration process started
- **Pattern**: Purple pulsing (red + blue combination)
- **Duration**: Throughout calibration process
- **Meaning**: System in calibration mode
- **Action**: Follow calibration procedure with reference solutions

#### 🟢 **Green Flash** - Success/Completion
- **When**: Successful operation completion
- **Pattern**: Single or double green flash
- **Meaning**: Operation completed successfully (calibration, measurement, etc.)
- **Action**: None - operation successful

---

### **Network & Connectivity**

#### 🔵 **Blue Breathing** - BLE Advertising
- **When**: Bluetooth advertising active
- **Pattern**: Smooth blue breathing effect
- **Meaning**: System discoverable via Bluetooth for mobile app connection
- **Action**: Connect via mobile app if needed

#### 🔵 **Blue Solid** - WiFi Connected
- **When**: WiFi connection established
- **Pattern**: Solid blue for 1 second
- **Meaning**: Successfully connected to WiFi network
- **Action**: None - connection established

#### 🔷 **Blue-White Alternating** - BLE Data Transfer
- **When**: Transferring data via Bluetooth
- **Pattern**: Alternating blue and white flashes
- **Meaning**: Calibration data or settings being transferred via BLE
- **Action**: Keep mobile device close during transfer

#### 🟠 **Orange Disco** - No WiFi/Network Issues
- **When**: WiFi credentials missing or connection failed
- **Pattern**: Orange disco/strobe effect
- **Meaning**: Network connectivity problems
- **Action**: Check WiFi settings, configure network credentials

---

### **Warnings & Errors**

#### 🟡 **Yellow Flash** - Warning
- **When**: Non-critical issues detected
- **Pattern**: Single or double yellow flash
- **Meaning**: System warning (configuration change, minor issue)
- **Action**: Check system status, may continue operating

#### 🔴 **Red Double Flash** - Error Detected
- **When**: System error or sensor failure
- **Pattern**: Two quick red flashes, pause, repeat
- **Meaning**: Error condition requiring attention
- **Action**: Check sensor connections, restart if needed

#### 🔴 **Red Fast Blinking** - Critical Error
- **When**: Critical system failure
- **Pattern**: Rapid red blinking (4Hz)
- **Meaning**: Critical error requiring immediate attention
- **Action**: Power cycle system, check hardware connections

#### 🔴🟢 **Red-Green Alternating** - Error Recovery
- **When**: System attempting automatic error recovery
- **Pattern**: Alternating red and green flashes
- **Meaning**: System is trying to recover from an error
- **Action**: Wait for recovery, restart if pattern continues >30 seconds

---

### **Special Operations**

#### 🔴🟡 **Red-Yellow Alternating** - Sensor Error
- **When**: Specific sensor malfunction
- **Pattern**: Alternating red and yellow
- **Meaning**: pH, TDS, or temperature sensor issue
- **Action**: Check sensor connections and calibration

#### 🌈 **Rainbow Sequence** - Factory Reset
- **When**: Factory reset in progress
- **Pattern**: Red → Yellow → Green → Cyan → Blue → Purple sequence
- **Duration**: 1-2 seconds
- **Meaning**: System returning to factory defaults
- **Action**: Reconfigure system after completion

#### 🟠 **Orange Breathing** - OTA Update
- **When**: Firmware update in progress
- **Pattern**: Smooth orange breathing effect
- **Duration**: 2-10 minutes depending on update size
- **Meaning**: Firmware being updated over-the-air
- **Action**: **DO NOT POWER OFF** - wait for completion

---

## 🔧 Troubleshooting Guide

### **LED Not Working**
1. Check power supply and connections
2. Restart system by power cycling
3. LED hardware may need service

### **Continuous Red Patterns**
1. Power cycle the device
2. Check all sensor connections
3. Verify water level covers sensors
4. Contact support if issue persists

### **No Network Connectivity (Orange Disco)**
1. Check WiFi network is available
2. Verify WiFi credentials in mobile app
3. Move closer to WiFi router
4. Restart router if needed

### **Stuck in Calibration Mode (Purple)**
1. Complete calibration procedure with reference solutions
2. Use mobile app to exit calibration mode
3. Power cycle if unresponsive

---

## 📱 Mobile App Integration

The WaterBee LED patterns work in conjunction with the mobile app:

- **Real-time status**: LED shows current state while app provides details
- **Error codes**: LED indicates error type, app shows specific error message
- **Calibration guidance**: LED shows mode, app provides step-by-step instructions
- **Network setup**: LED shows connection status, app configures WiFi

---

## ⚡ Power-Saving Features

- **Idle power saving**: LED completely off during ready/idle states to maximize battery life
- **Automatic dimming**: LED brightness automatically adjusts for battery conservation
- **Sleep mode**: LED turns off during deep sleep to maximize battery life
- **Priority system**: Critical errors override normal patterns for safety
- **OTA protection**: LED patterns continue during firmware updates

---

## 📞 Support Information

If you encounter LED patterns not described in this guide or persistent error patterns:

1. **Document the pattern**: Note color, timing, and when it occurs
2. **Check system logs**: Use mobile app to view detailed status
3. **Power cycle**: Turn off for 10 seconds, then restart
4. **Contact support**: Provide LED pattern description and system details

---

## 🔄 Firmware Version

This LED guide applies to **WaterBee V4.8** firmware and later. Earlier versions may have different patterns. Check your firmware version in the mobile app under Settings → About.

---

*This guide covers all standard LED patterns. Custom patterns may be added through firmware updates. Always ensure you're running the latest firmware for the best experience and newest features.*