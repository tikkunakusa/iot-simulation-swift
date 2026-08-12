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
            let cPtr = UnsafeRawPointer(buffer).assumingMemoryBound(to: CChar.self)
            parse_modem_time_if_present(cPtr)
            if let responseString = String(validatingUTF8: cPtr) {
                print("Modem: \(responseString)")
            }
        }
    }
}
