public struct TrafficLight {
    public let pinR: Int32
    public let pinY: Int32
    public let pinG: Int32

    public init(r: Int32, y: Int32, g: Int32) {
        self.pinR = r
        self.pinY = y
        self.pinG = g
        
        // Konfigurasi pin sebagai output
        gpio_set_direction(gpio_num_t(r), GPIO_MODE_OUTPUT)
        gpio_set_direction(gpio_num_t(y), GPIO_MODE_OUTPUT)
        gpio_set_direction(gpio_num_t(g), GPIO_MODE_OUTPUT)
        
        // Matikan semua LED di awal
        setRed(false)
        setYellow(false)
        setGreen(false)
    }

    public func setRed(_ on: Bool) {
        gpio_set_level(gpio_num_t(pinR), on ? 1 : 0)
    }

    public func setYellow(_ on: Bool) {
        gpio_set_level(gpio_num_t(pinY), on ? 1 : 0)
    }

    public func setGreen(_ on: Bool) {
        gpio_set_level(gpio_num_t(pinG), on ? 1 : 0)
    }
}
