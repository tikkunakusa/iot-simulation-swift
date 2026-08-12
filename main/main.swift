@_cdecl("app_main")

func main() {
	print("\n=====================================================")
	print("🥭  ESP32 MANGO TELEMETRY SYSTEM INITIALIZED")
	print("=====================================================")
	print("📡 Modem 4G  : SIMCom A7670C (RX:22, TX:21, PWR:23)")
	print("🛰️  GPS Module: Neo-6M (RX:5, TX:6)")
	print("🌡️  DHT Sensor: DHT22 (GPIO 4)")
	print("=====================================================\n")

	// Inisialisasi sensor DHT22 pada GPIO 4
	let dht = DHT22(pin: 4)

	// Inisialisasi sensor GPS Neo-6M pada GPIO 5 (RX ESP32) dan GPIO 6 (TX ESP32) pada 9600 bps
	let gps = GPS(rxPin: 5, txPin: 6, baudRate: 9600)

	// Inisialisasi LED Traffic Light pada GPIO 17(R), 16(Y), 8(G)
	let trafficLight = TrafficLight(r: 17, y: 16, g: 8)

	// Inisialisasi Modem 4G SimCom A7670C
	let modem = Modem4G(rxPin: 22, txPin: 21, pwrPin: 23)

	print("[SYSTEM] ⏳ Menunggu modem 4G terhubung ke sinyal seluler (25 detik)...")
	for _ in 0..<50 {
		delay_ms(500)  // 50 * 500ms = 25 detik tepat
		modem.readResponse()
	}

	print("[MODEM ] 🔄 Sinkronisasi AT Command...")
	modem.sendCommand("AT\r\n")
	delay_ms(200)
	modem.readResponse()
	modem.sendCommand("ATE0\r\n")
	delay_ms(200)
	modem.readResponse()

	SNTP.initialize()
	MQTT.start(brokerUri: "tcp://test.mosquitto.org:1883")

	var counter = 0
	var tickCount = 0

	var tempLatitudes: [Double?] = []
	var tempLongitudes: [Double?] = []

	while true {
		// --- Animasi Sederhana Traffic Light (Tiap 1 Detik) ---
		if tickCount == 0 {
			let state = counter % 3
			trafficLight.setRed(state == 0)
			trafficLight.setYellow(state == 1)
			trafficLight.setGreen(state == 2)
			counter += 1
		}

		// Update GPS (4x per second)
		gps.update()
		if let location = gps.getLocation() {
			tempLatitudes.append(location.latitude)
			tempLongitudes.append(location.longitude)
		} else {
			tempLatitudes.append(nil)
			tempLongitudes.append(nil)
		}

		// Setiap 4 ticks (4 * 250ms = 1 detik)
		if tickCount == 3 {
			var currentTemp: Float? = nil
			var currentHum: Float? = nil

			// Membaca dari DHT22 setiap 3 detik agar sensor stabil & bebas error phase-B
			if counter % 3 == 0 {
				if let data = dht.read() {
					currentTemp = data.temperature
					currentHum = data.humidity
					print_dht_data(data.humidity, data.temperature)
				} else {
					print("[DHT22 ] ⚠️ Sensor sibuk, mencoba membaca ulang di siklus berikutnya...")
				}
			}

			let epochTime = SNTP.currentEpoch

			DataManager.shared.addRecord(
				timestamp: epochTime,
				temperature: currentTemp,
				humidity: currentHum,
				latitudes: tempLatitudes,
				longitudes: tempLongitudes
			)

			DataManager.shared.processQueue()

			tempLatitudes.removeAll(keepingCapacity: true)
			tempLongitudes.removeAll(keepingCapacity: true)
		}

		modem.readResponse()

		tickCount = (tickCount + 1) % 4
		delay_ms(250)  // Delay 0.25 detik presisi
	}
}
