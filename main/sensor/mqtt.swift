public class MQTT {
    public static func start(brokerUri: String) {
        brokerUri.withCString { brokerUriPtr in
            mqtt_init_and_start(brokerUriPtr)
        }
    }
    
    public static func publish(topic: String, data: String) {
        topic.withCString { topicPtr in
            data.withCString { dataPtr in
                mqtt_publish(topicPtr, dataPtr)
            }
        }
    }
    
    public static var isConnected: Bool {
        return mqtt_is_connected()
    }
}
