@_cdecl("app_main")

func main() {
	print("Hello, world!")
	let dhtSensor = DHT22(pin: 4)

	while true {
		if let data = dhtSensor.read() {
			print("humidity: \(Int(data.humidity)), temperature: \(Int(data.temperature))")
		} else {
			print("Failed to read DHT22")
		}
		vTaskDelay(100)
	}
}
