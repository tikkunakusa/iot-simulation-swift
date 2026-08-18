public class Modem4G {
    let rxPin: Int32
    let txPin: Int32
    let pwrPin: Int32
    let baudRate: Int32

    // Referensi tunggal
    public static var shared: Modem4G!

    public init(rxPin: Int32, txPin: Int32, pwrPin: Int32, baudRate: Int32 = 115200) {
        self.rxPin = rxPin
        self.txPin = txPin
        self.pwrPin = pwrPin
        self.baudRate = baudRate

        modem_init(rxPin, txPin, pwrPin, baudRate)
        Modem4G.shared = self
    }

    public func sendCommand(_ command: String) {
        command.withCString { cStr in
            modem_send_command(cStr)
        }
    }

    public func powerCycle() {
        modem_power_cycle(pwrPin)
    }

    public func readResponse() {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let bytesRead = modem_read_data(buffer, Int32(bufferSize))
        if bytesRead > 0 {
            // Bersihkan karakter non-ASCII agar String(cString:) tidak gagal/hilang
            for i in 0..<Int(bytesRead) {
                let byte = buffer[i]
                if byte < 32 && byte != 10 && byte != 13 && byte != 9 {
                    buffer[i] = 32 // ganti control character dengan spasi
                } else if byte > 126 {
                    buffer[i] = 63 // ganti byte tinggi dengan '?'
                }
            }
            buffer[Int(bytesRead)] = 0
            
            let cPtr = UnsafeRawPointer(buffer).assumingMemoryBound(to: CChar.self)
            parse_modem_time_if_present(cPtr)
            parse_modem_gnss_if_present(cPtr)
            parse_modem_csq_if_present(cPtr)
            parse_modem_mqtt_if_present(cPtr)
            
            var hasPrintable = false
            for i in 0..<Int(bytesRead) {
                let b = buffer[i]
                if b > 32 && b <= 126 {
                    hasPrintable = true
                    break
                }
            }
            
            if hasPrintable {
                print("Modem: \(String(cString: cPtr))")
            }
        }
    }

    /// Turn on GNSS power on SIMCom A7670C modem
    public func enableGNSS() {
        sendCommand("AT+CGNSSPWR=1\r\n")
    }

    /// Request GNSS location info (+CGNSSINFO)
    public func requestGNSSInfo() {
        sendCommand("AT+CGNSSINFO\r\n")
    }

    /// Request Cell Tower LBS location (+CLBS=1,1)
    public func requestLBSLocation() {
        sendCommand("AT+CLBS=1,1\r\n")
    }

    /// Request signal quality (+CSQ)
    public func requestSignalQuality() {
        sendCommand("AT+CSQ\r\n")
    }

    /// Print current signal strength status
    public func printSignalStatus() {
        modem_print_signal_status()
    }

    /// Check whether cellular signal is valid (RSSI > 0 and RSSI < 99)
    public var hasSignal: Bool {
        return modem_has_signal()
    }

    /// Get last parsed RSSI value (0-31, or 99 if unknown)
    public var signalStrengthRSSI: Int32 {
        return modem_get_rssi()
    }

    /// Get signal strength in dBm (-113 dBm to -51 dBm, or -999 if unknown)
    public var signalStrengthDBm: Int32 {
        return modem_get_signal_dbm()
    }

    /// Get last parsed location from Modem GNSS/LBS
    public func getLocation() -> GPSData? {
        if modem_gnss_has_fix() {
            return GPSData(
                latitude: modem_gnss_get_latitude(),
                longitude: modem_gnss_get_longitude()
            )
        }
        return nil
    }
}
