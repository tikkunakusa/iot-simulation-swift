public class Led {
    private let handle: espp_led_handle_t
    private let channel: Int32
    
    public init(gpio: Int32, channel: Int32 = 0, timer: Int32 = 0) {
        self.channel = channel
        self.handle = espp_led_init(gpio, channel, timer)
    }
    
    deinit {
        espp_led_deinit(self.handle)
    }
    
    @discardableResult
    public func setDuty(_ dutyPercent: Float) -> Bool {
        return espp_led_set_duty(self.handle, self.channel, dutyPercent)
    }
    
    @discardableResult
    public func setFadeWithTime(dutyPercent: Float, fadeTimeMs: UInt32) -> Bool {
        return espp_led_set_fade_with_time(self.handle, self.channel, dutyPercent, fadeTimeMs)
    }
}
