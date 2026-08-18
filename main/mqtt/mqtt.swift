public class MQTT {
    public static var isConnected: Bool = false
    
    public static func start(brokerUri: String) {
        guard let modem = Modem4G.shared else { return }
        
        modem_reset_mqtt_connect_status()
        
        print("[MQTT  ] 📡 Inisialisasi APN & Network Context (AT+CGDCONT / AT+CGACT)...")
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
        
        print("[MQTT  ] 🌐 Mengaktifkan TCP Network Stack (AT+NETOPEN)...")
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
        
        print("[MQTT  ] ⚙️ Memulai service (AT+CMQTTSTART)...")
        modem.sendCommand("AT+CMQTTSTART\r\n")
        for _ in 0..<15 {
            delay_ms(100)
            modem.readResponse()
        }
        
        print("[MQTT  ] 🆔 Register Client ID (AT+CMQTTACCQ)...")
        modem.sendCommand("AT+CMQTTACCQ=0,\"esp32c6_889875b3\",0\r\n")
        for _ in 0..<10 {
            delay_ms(100)
            modem.readResponse()
        }
        
        let hasTcp = brokerUri.withCString { cStr in
            return strncmp(cStr, "tcp://", 6) == 0
        }
        let formattedUri = hasTcp ? brokerUri : "tcp://\(brokerUri)"
        print("[MQTT  ] 🔌 Menghubungkan ke broker \(formattedUri)...")
        modem.sendCommand("AT+CMQTTCONNECT=0,\"\(formattedUri)\",60,1\r\n")
        
        for _ in 0..<40 {
            delay_ms(100) // Polling 4 detik untuk menangkap balasan URC (+CMQTTCONNECT: 0,0)
            modem.readResponse()
            if modem_is_mqtt_connected() {
                break
            }
        }
        
        isConnected = modem_is_mqtt_connected()
        if isConnected {
            print("[MQTT  ] ✅ Terhubung ke broker MQTT!")
        } else {
            print("[MQTT  ] ⚠️ Belum terhubung ke broker MQTT (Menunggu sinyal/jaringan).")
        }
    }
    
    @discardableResult
    public static func publish(topic: String, data: String) -> Bool {
        guard let modem = Modem4G.shared else { return false }
        
        print("[MQTT  ] 📶 Memeriksa kekuatan sinyal modem...")
        modem.requestSignalQuality()
        for _ in 0..<3 {
            delay_ms(100)
            modem.readResponse()
        }
        modem.printSignalStatus()
        
        if !modem.hasSignal {
            print("[MQTT  ] ⚠️ Tidak ada sinyal seluler (CSQ: \(modem.signalStrengthRSSI)). Pembatalan publish, data tetap disimpan di buffer FIFO.")
            return false
        }
        
        if !isConnected {
            print("[MQTT  ] ⚠️ Belum terhubung ke broker, mengabaikan publish.")
            return false
        }
        
        modem_reset_mqtt_pub_status()
        
        print("[MQTT  ] 📝 Setting topik '\(topic)' (\(topic.utf8.count) bytes)...")
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
        
        print("[MQTT  ] 📦 Setting payload (\(data.utf8.count) bytes)...")
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
        
        print("[MQTT  ] 🚀 Mengeksekusi AT+CMQTTPUB (QoS 1)...")
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
            print("[MQTT  ] ✅ PUBLISH SUKSES! (QoS 1)")
            return true
        } else {
            print("[MQTT  ] ❌ PUBLISH GAGAL / Timeout (QoS 1).")
            return false
        }
    }
}
