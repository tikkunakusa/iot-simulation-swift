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
}
