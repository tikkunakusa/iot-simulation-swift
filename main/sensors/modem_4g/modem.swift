public class Modem4G {
    public let rxPin: Int32
    public let txPin: Int32
    public let pwrPin: Int32
    public let baudRate: Int32

    public static var shared: Modem4G!

    public init(rxPin: Int32, txPin: Int32, pwrPin: Int32, baudRate: Int32 = 115200) {
        self.rxPin = rxPin
        self.txPin = txPin
        self.pwrPin = pwrPin
        self.baudRate = baudRate

        modem_init(rxPin, txPin, pwrPin, baudRate)
        Modem4G.shared = self
    }

    /// Send raw string / AT command to the modem
    public func sendCommand(_ command: String) {
        command.withCString { cStr in
            modem_send_command(cStr)
        }
    }

    /// Flush incoming UART RX buffer
    public func flush() {
        modem_flush_rx()
    }

    /// Trigger power pulse on PWRKEY pin
    public func powerPulse(activeLowMs: Int32 = 1200, waitBootMs: Int32 = 3000) {
        modem_power_pulse(pwrPin, activeLowMs, waitBootMs)
    }

    /// Read any incoming response from UART buffer
    public func readResponse(timeoutMs: Int32 = 200, printOutput: Bool = true) -> String {
        let bufferSize = 2048
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let bytesRead = modem_read_data_timeout(buffer, Int32(bufferSize), timeoutMs)
        if bytesRead > 0 {
            // Sanitize control characters except newline and carriage return
            for i in 0..<Int(bytesRead) {
                let byte = buffer[i]
                if byte < 32 && byte != 10 && byte != 13 && byte != 9 {
                    buffer[i] = 32
                } else if byte > 126 {
                    buffer[i] = 63
                }
            }
            buffer[Int(bytesRead)] = 0
            
            let cPtr = UnsafeRawPointer(buffer).assumingMemoryBound(to: CChar.self)
            parse_modem_csq_if_present(cPtr)
            
            let respStr = String(cString: cPtr)
            if printOutput {
                var hasPrintable = false
                for i in 0..<Int(bytesRead) {
                    let b = buffer[i]
                    if b > 32 && b <= 126 {
                        hasPrintable = true
                        break
                    }
                }
                if hasPrintable {
                    print(respStr)
                }
            }
            return respStr
        }
        return ""
    }

    /// Send command, wait for response with timeout, and print result
    @discardableResult
    public func sendAndRead(
        command: String,
        timeoutMs: Int32 = 1000,
        retries: Int = 1,
        stepTitle: String? = nil
    ) -> String {
        if let title = stepTitle {
            print("\n------------------------------------------------------------")
            print("▶️  \(title)")
            print("📤 TX: \(command)")
        }
        
        var combinedResponse = ""
        for _ in 0..<retries {
            flush()
            sendCommand(command)
            
            // Read response in chunks over the timeout period
            var elapsed: Int32 = 0
            let stepDelay: Int32 = 100
            
            while elapsed < timeoutMs {
                delay_ms(UInt32(stepDelay))
                elapsed += stepDelay
                let chunk = readResponse(timeoutMs: 50, printOutput: false)
                if !chunk.isEmpty {
                    combinedResponse += chunk
                    
                    var shouldBreak = false
                    combinedResponse.withCString { cStr in
                        if modem_resp_contains(cStr, "OK\r\n") || 
                           modem_resp_contains(cStr, "ERROR\r\n") ||
                           modem_resp_contains(cStr, "+CME ERROR:") ||
                           modem_resp_contains(cStr, "+CMS ERROR:") {
                            shouldBreak = true
                        }
                    }
                    if shouldBreak {
                        break
                    }
                }
            }
            
            if !combinedResponse.isEmpty {
                break
            }
        }

        if !combinedResponse.isEmpty {
            combinedResponse.withCString { cStr in
                modem_print_sanitized("📥 RX", cStr)
            }
        } else {
            print("📥 RX: ⚠️ (No response / Timeout after \(timeoutMs)ms)")
        }
        
        return combinedResponse
    }


    /// Set UART baud rate dynamically
    @discardableResult
    public func setBaudRate(_ rate: Int32) -> Bool {
        return modem_set_baudrate(rate)
    }

    /// Reconfigure RX and TX pins dynamically
    public func reconfigurePins(rxPin: Int32, txPin: Int32) {
        modem_reconfigure_pins(rxPin, txPin)
    }

    /// Read raw bytes and print in HEX (useful for sniffer/debugging)
    public func readResponseRaw(timeoutMs: Int32 = 200) {
        let bufferSize = 512
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let bytesRead = modem_read_data_timeout(buffer, Int32(bufferSize), timeoutMs)
        if bytesRead > 0 {
            modem_print_raw_hex(buffer, bytesRead)
        }
    }

    /// Print signal strength status in formatted bars
    public func printSignalStatus() {
        modem_print_signal_status()
    }

    /// Check if cellular signal is valid
    public var hasSignal: Bool {
        return modem_has_signal()
    }

    /// Get current RSSI (0-31, 99=unknown)
    public var signalStrengthRSSI: Int32 {
        return modem_get_rssi()
    }

    /// Get current signal in dBm
    public var signalStrengthDBm: Int32 {
        return modem_get_signal_dbm()
    }
}


