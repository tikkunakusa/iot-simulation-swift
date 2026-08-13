public class MQTT {
    public static var isConnected: Bool = false
    
    public static func start(brokerUri: String) {
        guard let modem = Modem4G.shared else { return }
        
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
        }
        
        isConnected = true
    }
    
    public static func publish(topic: String, data: String) {
        guard let modem = Modem4G.shared else { return }
        
        if !isConnected {
            print("[MQTT  ] ⚠️ Belum terhubung ke broker, mengabaikan publish.")
            return
        }
        
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
        
        for _ in 0..<20 {
            delay_ms(100) // Polling 2 detik untuk menangkap balasan URC (+CMQTTPUB: 0,0)
            modem.readResponse()
        }
        print("[MQTT  ] ✅ PUBLISH SUKSES! (QoS 1)")
    }
}
