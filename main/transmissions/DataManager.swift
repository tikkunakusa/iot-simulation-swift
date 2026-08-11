public struct SensorRecord {
    var timestamp: Int
    var temperature: Float?
    var humidity: Float?
    var latitudes: [Double?]
    var longitudes: [Double?]
}

public class DataManager {
    public static let shared = DataManager()
    
    private var records: [SensorRecord] = []
    private let maxRecords = 3600 // 1 hour max cache (FIFO)
    
    private let mqttTopic = "mango/shipment/telemetry"
    private let deviceId = "c3337035-0444-4859-bf8b-b603eb150d63"
    
    private init() {}
    
    public func addRecord(timestamp: Int, temperature: Float?, humidity: Float?, latitudes: [Double?], longitudes: [Double?]) {
        let record = SensorRecord(
            timestamp: timestamp,
            temperature: temperature,
            humidity: humidity,
            latitudes: latitudes,
            longitudes: longitudes
        )
        
        records.append(record)
        
        // FIFO logic to keep maximum of 1 hour data (3600 records)
        if records.count > maxRecords {
            records.removeFirst(records.count - maxRecords)
        }
    }
    
    public func processQueue() {
        // Publish when we have at least 60 collected data points (1 minute)
        if records.count >= 60 {
            if MQTT.isConnected {
                transmitData()
            } else {
                print("DataManager: Menunggu koneksi MQTT untuk mengirim \(records.count) data...")
            }
        }
    }
    
    private func floatToString(_ val: Float) -> String {
        var buffer = [CChar](repeating: 0, count: 32)
        format_float_to_string(val, &buffer, 32)
        return String(cString: buffer)
    }
    
    private func doubleToString(_ val: Double) -> String {
        var buffer = [CChar](repeating: 0, count: 32)
        format_double_to_string(val, &buffer, 32)
        return String(cString: buffer)
    }
    
    private func transmitData() {
        // Construct JSON string manually to avoid heavy Foundation imports
        var jsonString = "{\"device_id\":\"\(deviceId)\",\"log\":["
        
        for (index, record) in records.enumerated() {
            var logEntry = "{"
            logEntry += "\"timestamp\":\(record.timestamp),"
            
            // Format Float safely
            logEntry += "\"temperature\":" + (record.temperature.map { floatToString($0) } ?? "null") + ","
            logEntry += "\"humidity\":" + (record.humidity.map { floatToString($0) } ?? "null") + ","
            
            // Format latitudes array
            logEntry += "\"latitude\":["
            logEntry += record.latitudes.map { $0.map { doubleToString($0) } ?? "null" }.joined(separator: ",")
            logEntry += "],"
            
            // Format longitudes array
            logEntry += "\"longitude\":["
            logEntry += record.longitudes.map { $0.map { doubleToString($0) } ?? "null" }.joined(separator: ",")
            logEntry += "]"
            
            logEntry += "}"
            
            jsonString += logEntry
            if index < records.count - 1 {
                jsonString += ","
            }
        }
        
        jsonString += "]}"
        
        print("DataManager: Mengirim \(records.count) record ke topik '\(mqttTopic)'")
        MQTT.publish(topic: mqttTopic, data: jsonString)
        
        // Clear records after transmission
        records.removeAll(keepingCapacity: true)
    }
}
