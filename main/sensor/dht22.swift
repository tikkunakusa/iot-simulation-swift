// Pastikan Anda sudah mengimpor modul C/bridging header yang mengekspos library dht
// import dht
// import esp_idf_hal

public struct DHT22 {
	/// Pin GPIO yang terhubung ke pin data DHT22
	public let pin: Int32  // gpio_num_t umumnya di-bridge sebagai Int32 di Swift

	/// Inisialisasi koneksi DHT22
	/// - Parameter pin: Nomor pin GPIO ESP32-C6
	public init(pin: Int32) {
		self.pin = pin
	}

	/// Membaca data kelembaban dan suhu dari sensor
	/// - Returns: Tuple berisi (humidity, temperature) jika berhasil, atau nil jika gagal (misal: timeout/checksum error).
	public func read() -> (humidity: Float, temperature: Float)? {
		var humidity: Float = 0.0
		var temperature: Float = 0.0

		// Menggunakan DHT_TYPE_AM2301 yang juga menaungi DHT22/AM2302
		// Konstanta ini berasal dari dht_sensor_type_t di library C.
		let status = dht_read_float_data(DHT_TYPE_AM2301, gpio_num_t(pin), &humidity, &temperature)

		// 0 biasanya merepresentasikan ESP_OK pada ESP-IDF
		if status == 0 {
			return (humidity, temperature)
		} else {
			return nil
		}
	}
}
