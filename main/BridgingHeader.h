#ifndef BRIDGING_HEADER_H
#define BRIDGING_HEADER_H

#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "sdkconfig.h"
#include <dht.h>
#include "driver/ledc.h"

#include "led_wrapper.h"
#include "wifi_wrapper.h"
#include "mqtt_wrapper.h"
#include "sntp_wrapper.h"
#include "adc_wrapper.h"

#endif
