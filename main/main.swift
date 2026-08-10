@_cdecl("app_main")

func main() {
	print("Hello, world!")

	print("Connecting to Wi-Fi Wokwi-GUEST...")
	WiFi.connect(ssid: "@tiko.aqsa", password: "Claudebussyxxx2")

	let dhtSensor = DHT22(pin: 4)
	let mq135Sensor = MQ135(channel: 3)  // GPIO3 is ADC1 Channel 3
	// let ledKit = Led(gpio: 2, channel: 0, timer: 0)
	var wasWifiConnected = false
	var wasMqttConnected = false
	var payloadBuffer = "[\n]"
	var secondsCounter = 0

	// Traffic Light LEDs
	let redLed = Led(gpio: 7, channel: 1, timer: 1)
	let yellowLed = Led(gpio: 6, channel: 2, timer: 1)
	let greenLed = Led(gpio: 15, channel: 3, timer: 1)

	var isLedOn = false
	var tick = 0

	while true {
		// Check Wi-Fi connection status
		let isWifiConnected = WiFi.isConnected
		if isWifiConnected && !wasWifiConnected {
			print("Wi-Fi successfully connected!")
			print("Initializing SNTP for time sync...")
			SNTP.initialize()
			print("Starting MQTT client...")
			MQTT.start(brokerUri: "mqtt://broker.hivemq.com")
		} else if !isWifiConnected && wasWifiConnected {
			print("Wi-Fi disconnected!")
		}
		wasWifiConnected = isWifiConnected

		// Check MQTT connection status
		let isMqttConnected = MQTT.isConnected
		if isMqttConnected && !wasMqttConnected {
			print("MQTT successfully connected to broker!")
		} else if !isMqttConnected && wasMqttConnected {
			print("MQTT disconnected from broker!")
		}
		wasMqttConnected = isMqttConnected

		isLedOn.toggle()

		if tick < 5 {
			// Calibration for the first 5 seconds
			redLed.setDuty(0.0)
			yellowLed.setDuty(100.0)
			greenLed.setDuty(0.0)
			if tick == 0 {
				print("Calibrating DHT22... (YELLOW)")
			}
		} else {
			// Data collection and traffic light logic every 1 second
			if let data = dhtSensor.read() {
				let hInt = Int(data.humidity)
				let hFrac = abs(Int((data.humidity - Float(hInt)) * 10))
				let tInt = Int(data.temperature)
				let tFrac = abs(Int((data.temperature - Float(tInt)) * 10))

				// Ready and successful read
				redLed.setDuty(0.0)
				yellowLed.setDuty(0.0)
				greenLed.setDuty(100.0)

				print("Reading: humidity: \(hInt).\(hFrac), temperature: \(tInt).\(tFrac)")

				let co2Reading = mq135Sensor.readCO2()
				print("CO2 Level: \(co2Reading) ppm")

				let tStr = "\(tInt).\(tFrac)"
				let hStr = "\(hInt).\(hFrac)"
				let currentTime = SNTP.currentTimeISO8601

				if secondsCounter > 0 {
					payloadBuffer += ",\n"
				}

				let record =
					"{\"device_id\":\"IoT_01\",\"timestamp\":\"\(currentTime)\",\"temperature\":\(tStr),\"humidity\":\(hStr),\"latitude\":-6.2000,\"longitude\":106.8160,\"battery\":100,\"status\":\"OK\"}"

				payloadBuffer += record
				secondsCounter += 1

				// Publish every 60 seconds
				if secondsCounter >= 60 {
					payloadBuffer += "\n]"
					let isMqttConnected = MQTT.isConnected
					if isMqttConnected {
						print("\n[TRANSMITTING] Topic: mango/shipment/telemetry")
						print("=== PAYLOAD ===")
						print(payloadBuffer)
						print("===============\n")

						MQTT.publish(topic: "mango/shipment/telemetry", data: payloadBuffer)
						print("Published 60 records to MQTT successfully.")
					} else {
						print("Failed to publish, MQTT not connected.")
					}

					// Reset buffer
					payloadBuffer = "[\n"
					secondsCounter = 0
				}
			} else {
				print("Failed to read DHT22")

				// Error
				redLed.setDuty(100.0)
				yellowLed.setDuty(0.0)
				greenLed.setDuty(0.0)
			}
		}

		tick += 1

		vTaskDelay(100)
	}
}
