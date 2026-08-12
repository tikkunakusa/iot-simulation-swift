public class SNTP {
    public static func initialize() {
        guard let modem = Modem4G.shared else { return }
        print("SNTP: Sinkronisasi waktu via AT Command...")
        // Set NTP server to pool.ntp.org, timezone to +7 (28 quarters) or +8 (32 quarters)
        modem.sendCommand("AT+CNTP=\"pool.ntp.org\",28\r\n")
        vTaskDelay(50)
        modem.sendCommand("AT+CNTP\r\n")
        vTaskDelay(100)
        modem.sendCommand("AT+CCLK?\r\n")
        vTaskDelay(50)
    }
    
    public static var currentEpoch: Int {
        return Int(get_epoch_timestamp())
    }
}
