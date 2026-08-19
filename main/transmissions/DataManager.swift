public struct SensorRecord {
	var timestamp: Int
	var temperature: Float?
	var humidity: Float?
	var latitudes: [Double?]
	var longitudes: [Double?]
}

public class DataManager {
	public static let shared = DataManager()

	private var records: [SensorRecord] = []
	private let maxRecords = 30  // 30 seconds max cache (FIFO testing)

	private let mqttTopic = "mango/shipment/telemetry"
	private let deviceId = "4733d00b-6658-4e8a-ad13-391940975e29"

	private init() {}

	public func addRecord(
		timestamp: Int, temperature: Float?, humidity: Float?, latitudes: [Double?],
		longitudes: [Double?]
	) {
		let record = SensorRecord(
			timestamp: timestamp,
			temperature: temperature,
			humidity: humidity,
			latitudes: latitudes,
			longitudes: longitudes
		)

		records.append(record)

		// FIFO logic to keep maximum of 30 seconds data (30 records)
		if records.count > maxRecords {
			records.removeFirst(records.count - maxRecords)
		}
	}

	public func processQueue() {
		let batchSize = 30
		// Kirim ke MQTT setiap batch 30 record (30 detik)
		if records.count >= batchSize {
			if MQTT.activeBearer == .cellular4G {
				print("[QUEUE ] 🔍 Memeriksa status sinyal seluler sebelum transmisi...")
				Modem4G.shared?.requestSignalQuality()
				for _ in 0..<3 {
					delay_ms(100)
					Modem4G.shared?.readResponse()
				}

				if let modem = Modem4G.shared, !modem.hasSignal {
					print("[QUEUE ] ⚠️ Sinyal seluler tidak tersedia (CSQ: \(modem.signalStrengthRSSI)).")
					if let ssid = MQTT.wifiSSID, let pass = MQTT.wifiPassword {
						print("[QUEUE ] 🚨 Memicu automatic failover ke Wi-Fi Tethering Hotspot...")
						let wifiOk = MQTT.switchToWiFi(ssid: ssid, password: pass)
						if !wifiOk {
							print("[QUEUE ] ⚠️ Wi-Fi belum siap. Data telemetri DITAMPUNG di antrian FIFO (\(records.count)/\(maxRecords)).")
							return
						}
					} else {
						print("[QUEUE ] ⚠️ Data telemetri DITAMPUNG di antrian FIFO: \(records.count)/\(maxRecords) record [\(records.count)s / maks 30 detik].")
						return
					}
				}
			} else {
				if !WiFi.isConnected {
					print("[QUEUE ] 🔄 Wi-Fi terputus, mencoba reconnect...")
					WiFi.reconnect()
				}
			}

			if !MQTT.isConnected {
				print("[QUEUE ] 🔄 Menghubungkan ulang MQTT (\(MQTT.activeBearer == .wifi ? "Wi-Fi" : "4G"))...")
				MQTT.reconnect()
			}

			if MQTT.isConnected {
				transmitData(batchSize: batchSize)
			} else {
				print("[QUEUE ] ⚠️ Menunggu koneksi MQTT/jaringan (Tersimpan di FIFO Cache: \(records.count)/\(maxRecords) record [\(records.count)s / maks 30 detik])...")
			}
		} else if records.count > 0 && records.count % 5 == 0 {
			print("[QUEUE ] ⏳ Mengumpulkan data telemetri: \(records.count)/\(batchSize) detik (Tersimpan di FIFO: \(records.count)/\(maxRecords))...")
		}
	}

	private func floatToString(_ val: Float) -> String {
		var buffer = [CChar](repeating: 0, count: 32)
		format_float_to_string(val, &buffer, 32)
		return String(cString: buffer)
	}

	private func doubleToString(_ val: Double) -> String {
		var buffer = [CChar](repeating: 0, count: 32)
		format_double_to_string(val, &buffer, 32)
		return String(cString: buffer)
	}

	private func transmitData(batchSize: Int = 10) {
		let countToSend = min(batchSize, records.count)
		guard countToSend > 0 else { return }

		// Construct JSON string manually to avoid heavy Foundation imports
		var jsonString = "{\"device_id\":\"\(deviceId)\",\"log\":["

		for index in 0..<countToSend {
			let record = records[index]
			var logEntry = "{"
			logEntry += "\"timestamp\":\(record.timestamp),"

			// Format Float safely
			logEntry += "\"temperature\":"
			if let temp = record.temperature {
				logEntry += floatToString(temp)
			} else {
				logEntry += "null"
			}
			logEntry += ",\"humidity\":"
			if let hum = record.humidity {
				logEntry += floatToString(hum)
			} else {
				logEntry += "null"
			}
			logEntry += ","

			// Format latitudes array
			logEntry += "\"latitude\":["
			for (latIdx, lat) in record.latitudes.enumerated() {
				if latIdx > 0 { logEntry += "," }
				if let lat = lat {
					logEntry += doubleToString(lat)
				} else {
					logEntry += "null"
				}
			}
			logEntry += "],"

			// Format longitudes array
			logEntry += "\"longitude\":["
			for (lonIdx, lon) in record.longitudes.enumerated() {
				if lonIdx > 0 { logEntry += "," }
				if let lon = lon {
					logEntry += doubleToString(lon)
				} else {
					logEntry += "null"
				}
			}
			logEntry += "]"

			logEntry += "}"

			jsonString += logEntry
			if index < countToSend - 1 {
				jsonString += ","
			}
		}

		jsonString += "]}"

		print("[QUEUE ] 🚀 Mempublikasikan batch \(countToSend) record ke topik '\(mqttTopic)' via \(MQTT.activeBearer == .wifi ? "Wi-Fi" : "4G") (Total antrian: \(records.count)/\(maxRecords))...")
		let isSuccess = MQTT.publish(topic: mqttTopic, data: jsonString)

		if isSuccess {
			// Hapus record tertua yang sudah terkirim dari antrian FIFO
			records.removeFirst(countToSend)
			print("[QUEUE ] ✅ Batch \(countToSend) record berhasil terkirim via \(MQTT.activeBearer == .wifi ? "Wi-Fi" : "4G"). Sisa antrian FIFO: \(records.count)/\(maxRecords)")
		} else {
			print("[QUEUE ] ⚠️ Publish gagal! \(countToSend) record tetap disimpan di antrian FIFO (\(records.count)/\(maxRecords)) untuk dikirim ulang nanti.")
		}
	}
}
