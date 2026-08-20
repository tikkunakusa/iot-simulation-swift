public struct SensorRecord {
	var timestamp: Int
	var temperature: Float?
	var humidity: Float?
	var latitudes: [Double?]
	var longitudes: [Double?]
}

public class DataManager {
	public static let shared = DataManager()

	public static let batchSize = 10      // 10 record = 10 detik per payload MQTT
	public static let maxBatches = 30     // Maksimal 30 batch disimpan di FIFO saat offline
	public static let maxRecords = maxBatches * batchSize // 300 record total (5 menit cache offline)

	private let batchSize = DataManager.batchSize
	private let maxBatches = DataManager.maxBatches
	private let maxRecords = DataManager.maxRecords

	private var records: [SensorRecord] = []

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

		// Logika FIFO: simpan maksimal 30 batch (300 record) saat offline
		if records.count > maxRecords {
			records.removeFirst(records.count - maxRecords)
		}
	}

	public func processQueue() {
		// Kirim ke MQTT setiap batch 10 record (10 detik)
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
							let totalBatches = (records.count + batchSize - 1) / batchSize
							print("[QUEUE ] ⚠️ Wi-Fi belum siap. Data telemetri DITAMPUNG di antrian FIFO: \(records.count)/\(maxRecords) record [\(totalBatches)/\(maxBatches) batch | \(records.count)s / maks \(maxRecords) detik].")
							return
						}
					} else {
						let totalBatches = (records.count + batchSize - 1) / batchSize
						print("[QUEUE ] ⚠️ Data telemetri DITAMPUNG di antrian FIFO: \(records.count)/\(maxRecords) record [\(totalBatches)/\(maxBatches) batch | \(records.count)s / maks \(maxRecords) detik].")
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
				// Kirim seluruh batch yang tersimpan di antrian FIFO secara berurutan (FIFO)
				while records.count >= batchSize && MQTT.isConnected {
					let success = transmitData(batchSize: batchSize)
					if !success {
						break
					}
					// Jeda singkat antar transmisi batch jika ada backlog data FIFO
					if records.count >= batchSize {
						delay_ms(200)
					}
				}
			} else {
				let totalBatches = (records.count + batchSize - 1) / batchSize
				print("[QUEUE ] ⚠️ Menunggu koneksi MQTT/jaringan (Tersimpan di FIFO Cache: \(records.count)/\(maxRecords) record [\(totalBatches)/\(maxBatches) batch | \(records.count)s / maks \(maxRecords) detik])...")
			}
		} else if records.count > 0 && records.count % 5 == 0 {
			let currentInBatch = records.count % batchSize == 0 ? batchSize : records.count % batchSize
			let totalBatches = (records.count + batchSize - 1) / batchSize
			print("[QUEUE ] ⏳ Mengumpulkan data telemetri: \(currentInBatch)/\(batchSize) detik (Tersimpan di FIFO: \(records.count)/\(maxRecords) record [\(totalBatches)/\(maxBatches) batch])...")
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

	@discardableResult
	private func transmitData(batchSize: Int = 10) -> Bool {
		let countToSend = min(batchSize, records.count)
		guard countToSend > 0 else { return false }

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

		let currentBatchNum = (records.count + batchSize - 1) / batchSize
		print("[QUEUE ] 🚀 Mempublikasikan batch \(countToSend) record ke topik '\(mqttTopic)' via \(MQTT.activeBearer == .wifi ? "Wi-Fi" : "4G") (Total antrian: \(records.count)/\(maxRecords) record [\(currentBatchNum)/\(maxBatches) batch])...")
		let isSuccess = MQTT.publish(topic: mqttTopic, data: jsonString)

		if isSuccess {
			// Hapus record tertua yang sudah terkirim dari antrian FIFO
			records.removeFirst(countToSend)
			let remainingBatches = (records.count + batchSize - 1) / batchSize
			print("[QUEUE ] ✅ Batch \(countToSend) record berhasil terkirim via \(MQTT.activeBearer == .wifi ? "Wi-Fi" : "4G"). Sisa antrian FIFO: \(records.count)/\(maxRecords) record [\(remainingBatches)/\(maxBatches) batch]")
			return true
		} else {
			let currentBatches = (records.count + batchSize - 1) / batchSize
			print("[QUEUE ] ⚠️ Publish gagal! \(countToSend) record tetap disimpan di antrian FIFO (\(records.count)/\(maxRecords) record [\(currentBatches)/\(maxBatches) batch]) untuk dikirim ulang nanti.")
			return false
		}
	}
}
