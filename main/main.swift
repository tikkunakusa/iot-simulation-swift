@_cdecl("app_main")

func main() {
    print("=== ESP32 Sensor Reader (DHT22, GPS, Modem & Traffic Light) Initialized ===")

    // Inisialisasi sensor DHT22 pada GPIO 4
    let dht = DHT22(pin: 4)

    // Inisialisasi sensor GPS Neo-6M pada GPIO 5 (RX ESP32) dan GPIO 6 (TX ESP32) pada 9600 bps
    let gps = GPS(rxPin: 5, txPin: 6, baudRate: 9600)
    
    // Inisialisasi LED Traffic Light pada GPIO 17(R), 16(Y), 8(G)
    let trafficLight = TrafficLight(r: 17, y: 16, g: 8)

    // Inisialisasi Modem 4G SimCom A7670C
    // Terhubung ke GPIO 21, 22, 23 (pin yang umumnya tersedia di FireBeetle 2 ESP32-C6)
    let modem = Modem4G(rxPin: 21, txPin: 22, pwrPin: 23)

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
            // Jika tidak ada fix, masukkan nilai nil (null)
            tempLatitudes.append(nil)
            tempLongitudes.append(nil)
        }

        // Setiap 4 ticks (4 * 250ms = 1 detik)
        if tickCount == 3 {
            // Membaca dari DHT22 - HANYA BOLEH SETIAP 2 DETIK
            // Kita gunakan variabel counter global untuk mengecek kelipatan 2 detik
            var currentTemp: Float? = nil
            var currentHum: Float? = nil
            
            // counter di atas bertambah 1 setiap detik
            if counter % 2 == 0 {
                if let data = dht.read() {
                    currentTemp = data.temperature
                    currentHum = data.humidity
                    // Panggil fungsi C print_dht_data langsung agar tidak memanggil dht.read() dua kali
                    print_dht_data(data.humidity, data.temperature)
                } else {
                    print("DHT22 -> Gagal membaca data")
                }
            }
            
            let epochTime = SNTP.currentEpoch
            
            // Simpan data ke manager (suhu/kelembaban mungkin nil di detik ganjil, itu wajar)
            DataManager.shared.addRecord(
                timestamp: epochTime,
                temperature: currentTemp,
                humidity: currentHum,
                latitudes: tempLatitudes,
                longitudes: tempLongitudes
            )
            
            // Evaluasi apakah bisa dikirim via MQTT
            DataManager.shared.processQueue()
            
            // Reset array GPS untuk detik berikutnya
            tempLatitudes.removeAll(keepingCapacity: true)
            tempLongitudes.removeAll(keepingCapacity: true)
        }

        // Baca response / output serial dari Modem
        modem.readResponse()

        tickCount = (tickCount + 1) % 4
        vTaskDelay(25) // Delay 0.25 detik (25 ticks pada 100Hz tick rate)
    }
}

