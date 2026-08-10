public class WiFi {
    public static func connect(ssid: String, password: String) {
        ssid.withCString { ssidPtr in
            password.withCString { passPtr in
                wifi_init_sta(ssidPtr, passPtr)
            }
        }
    }

    public static var isConnected: Bool {
        return wifi_is_connected()
    }
}
