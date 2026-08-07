@_cdecl("app_main")

func main() {
	print("Hello, world!")
	let dhtSensor = DHT22(pin: 4)

	while true {
		if let data = dhtSensor.read() {
			let hInt = Int(data.humidity)
			// Ekstrak 1 digit desimal dengan mengalikan selisihnya dengan 10
			let hFrac = abs(Int((data.humidity - Float(hInt)) * 10))
			
			let tInt = Int(data.temperature)
			let tFrac = abs(Int((data.temperature - Float(tInt)) * 10))
			
			print("humidity: \(hInt).\(hFrac), temperature: \(tInt).\(tFrac)")
		} else {
			print("Failed to read DHT22")
		}
		vTaskDelay(100)
	}
}
