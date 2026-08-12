#include "modem_wrapper.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/uart.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include "esp_timer.h"

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

static int64_t g_base_epoch = 1770876300LL; // Fallback epoch timestamp (August 2026)

extern "C" int64_t get_epoch_timestamp(void) {
    time_t now;
    time(&now);
    if (now > 1700000000LL) {
        return (int64_t)now;
    }
    int64_t uptime_sec = esp_timer_get_time() / 1000000LL;
    return g_base_epoch + uptime_sec;
}

extern "C" void set_epoch_timestamp(int64_t epoch_sec) {
    struct timeval tv;
    tv.tv_sec = (time_t)epoch_sec;
    tv.tv_usec = 0;
    settimeofday(&tv, NULL);
}

extern "C" void parse_modem_time_if_present(const char* str) {
    if (!str) return;
    const char* p = strstr(str, "+CCLK: \"");
    if (p) {
        int year, month, day, hour, min, sec;
        if (sscanf(p + 8, "%d/%d/%d,%d:%d:%d", &year, &month, &day, &hour, &min, &sec) == 6) {
            struct tm tm_info;
            memset(&tm_info, 0, sizeof(tm_info));
            tm_info.tm_year = (year < 100 ? year + 100 : year - 1900);
            tm_info.tm_mon = month - 1;
            tm_info.tm_mday = day;
            tm_info.tm_hour = hour;
            tm_info.tm_min = min;
            tm_info.tm_sec = sec;
            time_t t = mktime(&tm_info);
            if (t > 1700000000LL) {
                set_epoch_timestamp((int64_t)t);
                ESP_LOGI(TAG, "System time synced from modem AT+CCLK: %lld", (long long)t);
            }
        }
    }
}

// Embedded Swift Unicode Stubs to satisfy linker when standard library tables are omitted
extern "C" {
    bool _swift_stdlib_isInCB_Consonant(uint32_t scalar) { return false; }
    uint8_t _swift_stdlib_getGraphemeBreakProperty(uint32_t scalar) { return 0; }
    uint16_t _swift_stdlib_getNormData(uint32_t scalar) { return 0; }
    uint32_t _swift_stdlib_getComposition(uint32_t a, uint32_t b) { return 0; }
    uint16_t _swift_stdlib_getDecompositionEntry(uint32_t scalar) { return 0; }
    const uint8_t _swift_stdlib_nfd_decompositions[1] = {0};
}


