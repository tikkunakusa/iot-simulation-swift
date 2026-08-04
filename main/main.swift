@_cdecl("app_main")
func main() {
	print("Hello, world!")

	while true {
		vTaskDelay(1000)
	}
}
