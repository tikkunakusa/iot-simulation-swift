#include "modem_wrapper.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/uart.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include <string.h>

#define MODEM_UART_PORT UART_NUM_0
#define BUF_SIZE 1024

static const char *TAG = "MODEM_A7670C";

void modem_power_cycle(int pwr_pin) {
    if (pwr_pin >= 0) {
        ESP_LOGI(TAG, "Toggling PWRKEY (GPIO %d) to boot up modem...", pwr_pin);
        
        gpio_config_t io_conf = {};
        io_conf.intr_type = GPIO_INTR_DISABLE;
        io_conf.mode = GPIO_MODE_OUTPUT;
        io_conf.pin_bit_mask = (1ULL << pwr_pin);
        io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
        io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
        gpio_config(&io_conf);

        gpio_set_level((gpio_num_t)pwr_pin, 1);
        vTaskDelay(pdMS_TO_TICKS(100));
        
        gpio_set_level((gpio_num_t)pwr_pin, 0); 
        vTaskDelay(pdMS_TO_TICKS(1200));       
        
        gpio_set_level((gpio_num_t)pwr_pin, 1); 
        
        ESP_LOGI(TAG, "Waiting 3 seconds for modem to boot...");
        vTaskDelay(pdMS_TO_TICKS(3000));
    }
}

void modem_init(int rx_pin, int tx_pin, int pwr_pin, int baud_rate) {
    uart_config_t uart_config = {};
    uart_config.baud_rate = baud_rate;
    uart_config.data_bits = UART_DATA_8_BITS;
    uart_config.parity    = UART_PARITY_DISABLE;
    uart_config.stop_bits = UART_STOP_BITS_1;
    uart_config.flow_ctrl = UART_HW_FLOWCTRL_DISABLE;
    uart_config.source_clk = UART_SCLK_DEFAULT;
    
    ESP_ERROR_CHECK(uart_param_config(MODEM_UART_PORT, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(MODEM_UART_PORT, tx_pin, rx_pin, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));
    ESP_ERROR_CHECK(uart_driver_install(MODEM_UART_PORT, BUF_SIZE * 2, 0, 0, NULL, 0));
    
    ESP_LOGI(TAG, "Modem UART initialized on TX: %d, RX: %d", tx_pin, rx_pin);

    modem_power_cycle(pwr_pin);
}

void modem_send_command(const char* cmd) {
    uart_write_bytes(MODEM_UART_PORT, cmd, strlen(cmd));
}

int modem_read_data(uint8_t* buffer, int buffer_size) {
    int len = uart_read_bytes(MODEM_UART_PORT, buffer, buffer_size - 1, pdMS_TO_TICKS(20));
    if (len > 0) {
        buffer[len] = '\0'; 
    }
    return len;
}

extern "C" void format_double_to_string(double val, char* buffer, int max_len) {
    snprintf(buffer, max_len, "%.6f", val);
}

extern "C" void format_float_to_string(float val, char* buffer, int max_len) {
    snprintf(buffer, max_len, "%.2f", val);
}
