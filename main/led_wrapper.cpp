#include "led_wrapper.h"
#include "led.hpp"

extern "C" {

espp_led_handle_t espp_led_init(int gpio, int channel, int timer) {
    espp::Led::ChannelConfig channel_config;
    channel_config.gpio = (size_t)gpio;
    channel_config.channel = (ledc_channel_t)channel;
    channel_config.timer = (ledc_timer_t)timer;
    
    espp::Led::Config config;
    config.timer = (ledc_timer_t)timer;
    config.frequency_hz = 5000;
    config.channels.push_back(channel_config);
    
    espp::Led* led = new espp::Led(config);
    return (espp_led_handle_t)led;
}

void espp_led_deinit(espp_led_handle_t handle) {
    if (handle) {
        delete static_cast<espp::Led*>(handle);
    }
}

bool espp_led_set_duty(espp_led_handle_t handle, int channel, float duty_percent) {
    if (!handle) return false;
    espp::Led* led = static_cast<espp::Led*>(handle);
    return led->set_duty((ledc_channel_t)channel, duty_percent);
}

bool espp_led_set_fade_with_time(espp_led_handle_t handle, int channel, float duty_percent, uint32_t fade_time_ms) {
    if (!handle) return false;
    espp::Led* led = static_cast<espp::Led*>(handle);
    return led->set_fade_with_time((ledc_channel_t)channel, duty_percent, fade_time_ms);
}

}
