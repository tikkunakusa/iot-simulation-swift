public class WiFi {
    public static var isConnected: Bool {
        return wifi_manager_is_connected()
    }

    public static var ipAddress: String {
        var buffer = [CChar](repeating: 0, count: 32)
        wifi_manager_get_ip(&buffer, 32)
        return String(cString: buffer)
    }

    @discardableResult
    public static func connect(ssid: String, password: String, timeoutSec: Int = 15) -> Bool {
        print("[WIFI  ] 📡 Menghubungkan ke Wi-Fi Hotspot '\(ssid)'...")
        ssid.withCString { sStr in
            password.withCString { pStr in
                wifi_manager_init(sStr, pStr)
            }
        }

        for _ in 0..<(timeoutSec * 10) {
            delay_ms(100)
            if isConnected {
                print("[WIFI  ] ✅ Terhubung ke Wi-Fi Hotspot! IP: \(ipAddress)")
                return true
            }
        }

        print("[WIFI  ] ⚠️ Gagal terhubung ke Wi-Fi (Timeout \(timeoutSec) detik).")
        return false
    }

    public static func disconnect() {
        wifi_manager_disconnect()
    }

    public static func reconnect() {
        wifi_manager_reconnect()
    }
}
