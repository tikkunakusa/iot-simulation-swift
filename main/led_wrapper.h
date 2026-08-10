#ifndef LED_WRAPPER_H
#define LED_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* espp_led_handle_t;

espp_led_handle_t espp_led_init(int gpio, int channel, int timer);
void espp_led_deinit(espp_led_handle_t handle);
bool espp_led_set_duty(espp_led_handle_t handle, int channel, float duty_percent);
bool espp_led_set_fade_with_time(espp_led_handle_t handle, int channel, float duty_percent, uint32_t fade_time_ms);

#ifdef __cplusplus
}
#endif

#endif // LED_WRAPPER_H
