public class SNTP {
    public static func initialize() {
        sntp_init_client()
    }
    
    public static var currentTimeISO8601: String {
        var buffer = [CChar](repeating: 0, count: 32)
        sntp_get_time_iso8601(&buffer, Int32(buffer.count))
        return String(cString: buffer)
    }
}
