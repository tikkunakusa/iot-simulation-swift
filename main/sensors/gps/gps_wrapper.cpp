#include "gps_wrapper.h"
#include <TinyGPSPlus.h>
#include <driver/uart.h>
#include <driver/gpio.h>
#include <esp_log.h>

static const uart_port_t GPS_UART_PORT = UART_NUM_1;

extern "C" {

gps_handle_t gps_init(void) {
    return new TinyGPSPlus();
}

void gps_free(gps_handle_t handle) {
    if (handle) {
        delete static_cast<TinyGPSPlus*>(handle);
    }
}

void gps_update(gps_handle_t handle) {
    if (!handle) return;
    TinyGPSPlus *gps = static_cast<TinyGPSPlus*>(handle);
    uint8_t buf[128];
    int len = uart_read_bytes(GPS_UART_PORT, buf, sizeof(buf) - 1, 0);
    if (len > 0) {
        buf[len] = '\0';
        for (int i = 0; i < len; i++) {
            gps->encode(static_cast<char>(buf[i]));
        }
    }
}

bool gps_encode(gps_handle_t handle, char c) {
    if (!handle) return false;
    return static_cast<TinyGPSPlus*>(handle)->encode(c);
}

bool gps_location_is_valid(gps_handle_t handle) {
    if (!handle) return false;
    return static_cast<TinyGPSPlus*>(handle)->location.isValid();
}

double gps_location_lat(gps_handle_t handle) {
    if (!handle) return 0.0;
    return static_cast<TinyGPSPlus*>(handle)->location.lat();
}

double gps_location_lng(gps_handle_t handle) {
    if (!handle) return 0.0;
    return static_cast<TinyGPSPlus*>(handle)->location.lng();
}

uint32_t gps_location_age(gps_handle_t handle) {
    if (!handle) return UINT32_MAX;
    return static_cast<TinyGPSPlus*>(handle)->location.age();
}

uint32_t gps_chars_processed(gps_handle_t handle) {
    if (!handle) return 0;
    return static_cast<TinyGPSPlus*>(handle)->charsProcessed();
}

uint32_t gps_passed_checksum(gps_handle_t handle) {
    if (!handle) return 0;
    return static_cast<TinyGPSPlus*>(handle)->passedChecksum();
}

uint32_t gps_failed_checksum(gps_handle_t handle) {
    if (!handle) return 0;
    return static_cast<TinyGPSPlus*>(handle)->failedChecksum();
}

uint32_t gps_satellites_value(gps_handle_t handle) {
    if (!handle) return 0;
    return static_cast<TinyGPSPlus*>(handle)->satellites.value();
}

void gps_uart_init(int tx_pin, int rx_pin, int baud_rate) {
    uart_config_t uart_config = {};
    uart_config.baud_rate = baud_rate;
    uart_config.data_bits = UART_DATA_8_BITS;
    uart_config.parity = UART_PARITY_DISABLE;
    uart_config.stop_bits = UART_STOP_BITS_1;
    uart_config.flow_ctrl = UART_HW_FLOWCTRL_DISABLE;
    uart_config.source_clk = UART_SCLK_DEFAULT;

    if (!uart_is_driver_installed(GPS_UART_PORT)) {
        ESP_ERROR_CHECK(uart_driver_install(GPS_UART_PORT, 1024, 0, 0, NULL, 0));
    }
    ESP_ERROR_CHECK(uart_param_config(GPS_UART_PORT, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(GPS_UART_PORT, tx_pin, rx_pin, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));
}

void print_gps_location(double lat, double lng) {
    printf("GPS Location -> Latitude: %.6f, Longitude: %.6f\n", lat, lng);
}

void print_gps_status(gps_handle_t handle) {
    if (!handle) return;
    TinyGPSPlus *gps = static_cast<TinyGPSPlus*>(handle);
    if (gps->location.isValid()) {
        printf("GPS Fix! -> Latitude: %.6f, Longitude: %.6f (Sats: %lu)\n",
               gps->location.lat(), gps->location.lng(), (unsigned long)gps->satellites.value());
    } else {
        printf("Waiting for satellite lock... [Bytes rx: %lu | Sentences OK: %lu | Sats in view: %lu]\n",
               (unsigned long)gps->charsProcessed(),
               (unsigned long)gps->passedChecksum(),
               (unsigned long)gps->satellites.value());
    }
}

void print_dht_data(float humidity, float temperature) {
    printf("DHT22 -> Humidity: %.1f%%, Temperature: %.1f°C\n", humidity, temperature);
}

}
