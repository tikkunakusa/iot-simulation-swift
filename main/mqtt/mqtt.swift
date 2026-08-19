public enum NetworkBearer {
    case cellular4G
    case wifi
}

public class MQTT {
    public static var activeBearer: NetworkBearer = .cellular4G
    public static var brokerUri: String = "ssl://dfc14af1.ala.asia-southeast1.emqxsl.com:8883"
    public static var username: String? = "iot_sensor"
    public static var password: String? = "zonqy4-visXus-nacdex"

    public static var wifiSSID: String? = nil
    public static var wifiPassword: String? = nil

    public static var consecutiveFailures: Int = 0
    public static let maxFailuresBeforeFailover: Int = 3

    public static var isConnected: Bool {
        switch activeBearer {
        case .cellular4G:
            return modem_is_mqtt_connected()
        case .wifi:
            return wifi_mqtt_is_connected()
        }
    }

    public static func reconnect() {
        start(bearer: activeBearer, brokerUri: brokerUri, username: username, password: password)
    }

    public static func start(
        bearer: NetworkBearer = .cellular4G,
        brokerUri: String? = nil,
        username: String? = nil,
        password: String? = nil
    ) {
        if let uri = brokerUri { self.brokerUri = uri }
        if let u = username { self.username = u }
        if let p = password { self.password = p }

        self.activeBearer = bearer

        if bearer == .wifi {
            startWiFiMQTT()
        } else {
            startCellularMQTT()
        }
    }

    @discardableResult
    public static func switchToWiFi(ssid: String, password: String) -> Bool {
        self.wifiSSID = ssid
        self.wifiPassword = password
        print("\n[FAILOVER] 🔄 Mengalihkan jalur transmisi ke Wi-Fi Tethering Hotspot '\(ssid)'...")

        if !WiFi.connect(ssid: ssid, password: password, timeoutSec: 15) {
            print("[FAILOVER] ❌ Gagal terhubung ke Wi-Fi Tethering.")
            return false
        }

        // Initialize SNTP via Wi-Fi
        SNTP.initialize(bearer: .wifi)

        // Start Native MQTT client over Wi-Fi
        self.activeBearer = .wifi
        startWiFiMQTT()

        print("[FAILOVER] ⏳ Menunggu koneksi MQTT via Wi-Fi...")
        for _ in 0..<50 { // wait up to 5s
            delay_ms(100)
            if wifi_mqtt_is_connected() {
                break
            }
        }

        if isConnected {
            print("[FAILOVER] ✅ Berhasil terhubung ke Broker MQTT via Wi-Fi!")
            consecutiveFailures = 0
            return true
        } else {
            print("[FAILOVER] ⚠️ Belum terhubung ke Broker MQTT via Wi-Fi.")
            return false
        }
    }

    public static func switchTo4G() {
        print("\n[FAILOVER] 🔄 Mengalihkan jalur transmisi kembali ke 4G Seluler...")
        self.activeBearer = .cellular4G
        startCellularMQTT()
    }

    private static func startWiFiMQTT() {
        print("[MQTT-WIFI] 🌐 Memulai ESP-IDF Native MQTT Client ke \(brokerUri)...")
        let targetUri = brokerUri
        let u = username ?? ""
        let p = password ?? ""
        let clientId = "esp32c6_wifi_backup"

        targetUri.withCString { uriStr in
            u.withCString { userStr in
                p.withCString { passStr in
                    clientId.withCString { idStr in
                        wifi_mqtt_init(uriStr, userStr, passStr, idStr)
                    }
                }
            }
        }
    }

    private static func startCellularMQTT() {
        guard let modem = Modem4G.shared else { return }
        let targetUri = self.brokerUri
        modem_reset_mqtt_connect_status()

        print("[MQTT-4G ] 📡 Inisialisasi APN & Network Context (AT+CGDCONT / AT+CGACT)...")
        modem.sendCommand("AT+CGDCONT=1,\"IP\",\"internet\"\r\n")
        for _ in 0..<5 {
            delay_ms(100)
            modem.readResponse()
        }

        modem.sendCommand("AT+CGACT=1,1\r\n")
        for _ in 0..<10 {
            delay_ms(100)
            modem.readResponse()
        }

        print("[MQTT-4G ] 🌐 Mengaktifkan TCP Network Stack (AT+NETOPEN)...")
        modem.sendCommand("AT+NETOPEN\r\n")
        for _ in 0..<20 {
            delay_ms(100)
            modem.readResponse()
        }

        // Cleanup sesi MQTT sebelumnya jika ada
        modem.sendCommand("AT+CMQTTREL=0\r\n")
        delay_ms(100)
        modem.readResponse()
        modem.sendCommand("AT+CMQTTSTOP\r\n")
        delay_ms(100)
        modem.readResponse()

        let isSsl = targetUri.withCString { cStr in
            return strncmp(cStr, "ssl://", 6) == 0 || strncmp(cStr, "tcps://", 7) == 0 || strstr(cStr, ":8883") != nil
        }

        if isSsl {
            print("[MQTT-4G ] 🔒 Konfigurasi SSL/TLS Context (TLS 1.2, authmode=0)...")
            modem.sendCommand("AT+CSSLCFG=\"sslversion\",0,4\r\n")
            delay_ms(100)
            modem.readResponse()
            modem.sendCommand("AT+CSSLCFG=\"authmode\",0,0\r\n")
            delay_ms(100)
            modem.readResponse()
            modem.sendCommand("AT+CSSLCFG=\"ignorelocaltime\",0,1\r\n")
            delay_ms(100)
            modem.readResponse()
        }

        print("[MQTT-4G ] ⚙️ Memulai service (AT+CMQTTSTART)...")
        modem.sendCommand("AT+CMQTTSTART\r\n")
        for _ in 0..<15 {
            delay_ms(100)
            modem.readResponse()
        }

        let serverType = isSsl ? 1 : 0
        print("[MQTT-4G ] 🆔 Register Client ID (AT+CMQTTACCQ: server_type=\(serverType))...")
        modem.sendCommand("AT+CMQTTACCQ=0,\"esp32c6_889875b3\",\(serverType)\r\n")
        for _ in 0..<10 {
            delay_ms(100)
            modem.readResponse()
        }

        if isSsl {
            print("[MQTT-4G ] 🔗 Mengaitkan SSL Context (AT+CMQTTSSLCFG=0,0)...")
            modem.sendCommand("AT+CMQTTSSLCFG=0,0\r\n")
            delay_ms(100)
            modem.readResponse()
        }

        let hasPrefix = targetUri.withCString { cStr in
            return strncmp(cStr, "tcp://", 6) == 0 || strncmp(cStr, "ssl://", 6) == 0 || strncmp(cStr, "tcps://", 7) == 0
        }
        let prefix = isSsl ? "ssl://" : "tcp://"
        let formattedUri = hasPrefix ? targetUri : "\(prefix)\(targetUri)"

        print("[MQTT-4G ] 🔌 Menghubungkan ke broker \(formattedUri)...")
        if let u = self.username, let p = self.password {
            modem.sendCommand("AT+CMQTTCONNECT=0,\"\(formattedUri)\",60,1,\"\(u)\",\"\(p)\"\r\n")
        } else {
            modem.sendCommand("AT+CMQTTCONNECT=0,\"\(formattedUri)\",60,1\r\n")
        }

        for _ in 0..<60 {
            delay_ms(100) // Polling 6 detik untuk menangkap balasan URC (+CMQTTCONNECT: 0,0) handshake SSL
            modem.readResponse()
            if modem_is_mqtt_connected() {
                break
            }
        }

        if modem_is_mqtt_connected() {
            print("[MQTT-4G ] ✅ Terhubung ke broker MQTT via 4G!")
        } else {
            print("[MQTT-4G ] ⚠️ Belum terhubung ke broker MQTT via 4G (Menunggu sinyal/jaringan/handshake).")
        }
    }

    @discardableResult
    public static func publish(topic: String, data: String) -> Bool {
        switch activeBearer {
        case .cellular4G:
            let success = publishVia4G(topic: topic, data: data)
            if success {
                consecutiveFailures = 0
                return true
            } else {
                consecutiveFailures += 1
                print("[MQTT-4G ] ⚠️ Gagal publish 4G (\(consecutiveFailures)/\(maxFailuresBeforeFailover))")
                if consecutiveFailures >= maxFailuresBeforeFailover {
                    if let ssid = wifiSSID, let pass = wifiPassword {
                        print("[MQTT-4G ] 🚨 4G Modem bermasalah berturut-turut! Memulai Automatic Failover ke Wi-Fi...")
                        let wifiOk = switchToWiFi(ssid: ssid, password: pass)
                        if wifiOk {
                            print("[MQTT-WIFI] 🚀 Mencoba publish ulang payload via Wi-Fi...")
                            return publishViaWiFi(topic: topic, data: data)
                        }
                    }
                }
                return false
            }
        case .wifi:
            let success = publishViaWiFi(topic: topic, data: data)
            if success {
                consecutiveFailures = 0
            } else {
                consecutiveFailures += 1
            }
            return success
        }
    }

    private static func publishViaWiFi(topic: String, data: String) -> Bool {
        if !wifi_mqtt_is_connected() {
            print("[MQTT-WIFI] ⚠️ Wi-Fi MQTT belum terhubung, mencoba reconnect...")
            wifi_mqtt_reconnect()
            delay_ms(500)
            if !wifi_mqtt_is_connected() {
                return false
            }
        }

        print("[MQTT-WIFI] 🚀 Mengirim payload (\(data.utf8.count) bytes) ke topik '\(topic)' via Wi-Fi...")
        var success = false
        topic.withCString { tStr in
            data.withCString { dStr in
                success = wifi_mqtt_publish(tStr, dStr, 1)
            }
        }

        if success {
            print("[MQTT-WIFI] ✅ PUBLISH SUKSES via Wi-Fi! (QoS 1)")
        } else {
            print("[MQTT-WIFI] ❌ PUBLISH GAGAL via Wi-Fi.")
        }
        return success
    }

    private static func publishVia4G(topic: String, data: String) -> Bool {
        guard let modem = Modem4G.shared else { return false }

        print("[MQTT-4G ] 📶 Memeriksa kekuatan sinyal modem...")
        modem.requestSignalQuality()
        for _ in 0..<3 {
            delay_ms(100)
            modem.readResponse()
        }
        modem.printSignalStatus()

        if !modem.hasSignal {
            print("[MQTT-4G ] ⚠️ Tidak ada sinyal seluler (CSQ: \(modem.signalStrengthRSSI)). Pembatalan publish 4G.")
            return false
        }

        if !modem_is_mqtt_connected() {
            print("[MQTT-4G ] ⚠️ Belum terhubung ke broker via 4G, mengabaikan publish.")
            return false
        }

        modem_reset_mqtt_pub_status()

        print("[MQTT-4G ] 📝 Setting topik '\(topic)' (\(topic.utf8.count) bytes)...")
        modem.sendCommand("AT+CMQTTTOPIC=0,\(topic.utf8.count)\r\n")
        for _ in 0..<5 {
            delay_ms(100)
            modem.readResponse()
        }

        modem.sendCommand("\(topic)")
        for _ in 0..<5 {
            delay_ms(100)
            modem.readResponse()
        }

        print("[MQTT-4G ] 📦 Setting payload (\(data.utf8.count) bytes)...")
        modem.sendCommand("AT+CMQTTPAYLOAD=0,\(data.utf8.count)\r\n")
        for _ in 0..<5 {
            delay_ms(100)
            modem.readResponse()
        }

        modem.sendCommand("\(data)")
        for _ in 0..<10 {
            delay_ms(100)
            modem.readResponse()
        }

        print("[MQTT-4G ] 🚀 Mengeksekusi AT+CMQTTPUB (QoS 1)...")
        modem.sendCommand("AT+CMQTTPUB=0,1,60\r\n")

        var published = false
        for _ in 0..<25 {
            delay_ms(100) // Polling 2.5 detik untuk menangkap balasan URC (+CMQTTPUB: 0,0)
            modem.readResponse()
            if modem_is_mqtt_pub_success() {
                published = true
                break
            }
        }

        if published {
            print("[MQTT-4G ] ✅ PUBLISH SUKSES via 4G! (QoS 1)")
            return true
        } else {
            print("[MQTT-4G ] ❌ PUBLISH GAGAL / Timeout 4G (QoS 1).")
            return false
        }
    }
}
