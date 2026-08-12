public class MQTT {
    public static var isConnected: Bool = false
    
    public static func start(brokerUri: String) {
        guard let modem = Modem4G.shared else { return }
        
        print("MQTT: Memulai koneksi via AT Commands...")
        
        modem.sendCommand("AT+CMQTTSTART\r\n")
        vTaskDelay(100)
        
        modem.sendCommand("AT+CMQTTACCQ=0,\"esp32c6_client\",0\r\n")
        vTaskDelay(100)
        
        let hasTcp = brokerUri.withCString { cStr in
            return strncmp(cStr, "tcp://", 6) == 0
        }
        let formattedUri = hasTcp ? brokerUri : "tcp://\(brokerUri)"
        modem.sendCommand("AT+CMQTTCONNECT=0,\"\(formattedUri)\",60,1\r\n")
        vTaskDelay(200) // Tunggu agak lama untuk koneksi TCP
        
        isConnected = true
    }
    
    public static func publish(topic: String, data: String) {
        guard let modem = Modem4G.shared else { return }
        
        if !isConnected {
            return
        }
        
        // Topic
        modem.sendCommand("AT+CMQTTTOPIC=0,\(topic.utf8.count)\r\n")
        vTaskDelay(20)
        modem.sendCommand("\(topic)")
        vTaskDelay(20)
        
        // Payload
        modem.sendCommand("AT+CMQTTPAYLOAD=0,\(data.utf8.count)\r\n")
        vTaskDelay(20)
        modem.sendCommand("\(data)")
        vTaskDelay(20)
        
        // Publish
        modem.sendCommand("AT+CMQTTPUB=0,0,60\r\n")
        print("\n✅ [MQTT AT] Data dikirim ke topik \(topic)!")
    }
}
