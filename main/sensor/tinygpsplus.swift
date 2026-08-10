public struct GPSData {
    public let latitude: Double
    public let longitude: Double
}

public class GPS {
    private var handle: gps_handle_t
    
    /// Initialize GPS module on specified UART pins and baud rate
    /// - Parameters:
    ///   - rxPin: ESP32 RX pin connected to GPS TX (Default: GPIO 5)
    ///   - txPin: ESP32 TX pin connected to GPS RX (Default: GPIO 6)
    ///   - baudRate: Serial baud rate for Neo-6M (Default: 9600 bps)
    public init(rxPin: Int32 = 5, txPin: Int32 = 6, baudRate: Int32 = 9600) {
        self.handle = gps_init()
        gps_uart_init(txPin, rxPin, baudRate)
    }
    
    deinit {
        gps_free(self.handle)
    }
    
    /// Reads pending UART bytes natively in C++ buffer and feeds them to TinyGPS++ parser
    public func update() {
        gps_update(self.handle)
    }
    
    public func encode(char: CChar) -> Bool {
        return gps_encode(self.handle, char)
    }
    
    public func encode(string: String) {
        for char in string.utf8 {
            _ = gps_encode(self.handle, CChar(bitPattern: char))
        }
    }
    
    /// Returns valid location data if GPS fix is acquired
    public func getLocation() -> GPSData? {
        if gps_location_is_valid(self.handle) {
            return GPSData(
                latitude: gps_location_lat(self.handle),
                longitude: gps_location_lng(self.handle)
            )
        }
        return nil
    }

    /// Prints Latitude and Longitude if valid fix is acquired
    public func printLocation() {
        if gps_location_is_valid(self.handle) {
            print_gps_location(gps_location_lat(self.handle), gps_location_lng(self.handle))
        } else {
            print("Mencari sinyal GPS (waiting for fix)...")
        }
    }

    /// Prints detailed diagnostic status including byte counts, checksum status, and satellite fix
    public func printStatus() {
        print_gps_status(self.handle)
    }
}
