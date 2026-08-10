@_cdecl("app_main")

func main() {
    print("=== ESP32 GPS Neo-6M Reader Initialized ===")

    // Inisialisasi sensor GPS Neo-6M pada GPIO 5 (RX) dan GPIO 6 (TX) pada 9600 bps
    let gps = GPS(rxPin: 5, txPin: 6, baudRate: 9600)

    while true {
        // Baca byte UART secara aman via C++ buffer dan parse ke TinyGPS++
        gps.update()

        // Cetak lokasi jika sudah terkunci satelit (fix), atau cetak status pencarian jika belum
        if let location = gps.getLocation() {
            print_gps_location(location.latitude, location.longitude)
        } else {
            gps.printStatus()
        }

        vTaskDelay(100) // Delay 1 detik (100 ticks pada 100Hz tick rate)
    }
}
