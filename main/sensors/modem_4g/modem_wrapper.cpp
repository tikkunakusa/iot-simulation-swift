#include "modem_wrapper.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/uart.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include <string.h>
#include <stdio.h>

#define MODEM_UART_PORT UART_NUM_1
#define BUF_SIZE 2048

static const char *TAG = "MODEM_A7670C";

void modem_power_pulse(int pwr_pin, int active_low_ms, int wait_boot_ms) {
    if (pwr_pin >= 0) {
        ESP_LOGI(TAG, "Pulsing PWRKEY (GPIO %d) -> LOW for %d ms...", pwr_pin, active_low_ms);
        
        gpio_config_t io_conf = {};
        io_conf.intr_type = GPIO_INTR_DISABLE;
        io_conf.mode = GPIO_MODE_OUTPUT;
        io_conf.pin_bit_mask = (1ULL << pwr_pin);
        io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
        io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
        gpio_config(&io_conf);

        gpio_set_level((gpio_num_t)pwr_pin, 1);
        vTaskDelay(pdMS_TO_TICKS(100));
        
        // Active-LOW pulse to toggle modem power state
        gpio_set_level((gpio_num_t)pwr_pin, 0); 
        vTaskDelay(pdMS_TO_TICKS(active_low_ms));       
        
        // Return to HIGH state
        gpio_set_level((gpio_num_t)pwr_pin, 1); 
        
        if (wait_boot_ms > 0) {
            ESP_LOGI(TAG, "Waiting %d ms for modem...", wait_boot_ms);
            vTaskDelay(pdMS_TO_TICKS(wait_boot_ms));
        }
    }
}

void modem_power_cycle(int pwr_pin) {
    modem_power_pulse(pwr_pin, 1200, 3000);
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
    
    ESP_LOGI(TAG, "Modem UART initialized on TX: %d, RX: %d @ %d bps", tx_pin, rx_pin, baud_rate);

    if (pwr_pin >= 0) {
        gpio_config_t io_conf = {};
        io_conf.intr_type = GPIO_INTR_DISABLE;
        io_conf.mode = GPIO_MODE_OUTPUT;
        io_conf.pin_bit_mask = (1ULL << pwr_pin);
        io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
        io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
        gpio_config(&io_conf);
        gpio_set_level((gpio_num_t)pwr_pin, 1);
    }
}

void modem_send_command(const char* cmd) {
    if (!cmd) return;
    uart_write_bytes(MODEM_UART_PORT, cmd, strlen(cmd));
    uart_wait_tx_done(MODEM_UART_PORT, pdMS_TO_TICKS(500));
}

int modem_read_data(uint8_t* buffer, int buffer_size) {
    return modem_read_data_timeout(buffer, buffer_size, 200);
}

int modem_read_data_timeout(uint8_t* buffer, int buffer_size, int timeout_ms) {
    if (!buffer || buffer_size <= 0) return 0;
    int len = uart_read_bytes(MODEM_UART_PORT, buffer, buffer_size - 1, pdMS_TO_TICKS(timeout_ms));
    if (len > 0) {
        buffer[len] = '\0';
    } else {
        buffer[0] = '\0';
        len = 0;
    }
    return len;
}

void modem_flush_rx(void) {
    uart_flush_input(MODEM_UART_PORT);
}

static int g_modem_rssi = 99;
static int g_modem_ber = 99;

extern "C" void parse_modem_csq_if_present(const char* str) {
    if (!str) return;
    const char* p = strstr(str, "+CSQ:");
    if (p) {
        p += 5;
        while (*p == ' ') p++;
        int rssi = 99, ber = 99;
        if (sscanf(p, "%d,%d", &rssi, &ber) >= 1) {
            g_modem_rssi = rssi;
            g_modem_ber = ber;
        }
    }
}

extern "C" int modem_get_rssi(void) {
    return g_modem_rssi;
}

extern "C" int modem_get_ber(void) {
    return g_modem_ber;
}

extern "C" bool modem_has_signal(void) {
    return (g_modem_rssi > 0 && g_modem_rssi < 99);
}

extern "C" int modem_get_signal_dbm(void) {
    if (g_modem_rssi < 0 || g_modem_rssi > 31) {
        return -999;
    }
    return -113 + (g_modem_rssi * 2);
}

extern "C" void modem_print_signal_status(void) {
    if (g_modem_rssi == 99 || g_modem_rssi < 0) {
        printf("[MODEM ] 📶 Sinyal: ⚠️ Tidak Ada Sinyal / Unknown (CSQ: 99)\n");
        return;
    }
    
    int dbm = -113 + (g_modem_rssi * 2);
    const char* quality;
    const char* bar;
    
    if (g_modem_rssi >= 20) {
        quality = "Sangat Baik (Excellent)";
        bar = "[████]";
    } else if (g_modem_rssi >= 15) {
        quality = "Baik (Good)";
        bar = "[███░]";
    } else if (g_modem_rssi >= 10) {
        quality = "Cukup (Fair)";
        bar = "[██░░]";
    } else if (g_modem_rssi >= 1) {
        quality = "Lemah (Poor)";
        bar = "[█░░░]";
    } else {
        quality = "Sangat Lemah (Marginal)";
        bar = "[░░░░]";
    }
    
    printf("[MODEM ] 📶 Sinyal: %s (%d dBm | CSQ: %d/31 | %s)\n", 
           quality, dbm, g_modem_rssi, bar);
}

extern "C" bool modem_set_baudrate(int baud_rate) {
    esp_err_t err = uart_set_baudrate(MODEM_UART_PORT, baud_rate);
    return (err == ESP_OK);
}

extern "C" void modem_reconfigure_pins(int rx_pin, int tx_pin) {
    uart_set_pin(MODEM_UART_PORT, tx_pin, rx_pin, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
}

extern "C" void modem_print_raw_hex(const uint8_t* buffer, int len) {
    if (!buffer || len <= 0) return;
    printf("[RAW HEX (%d bytes)]: ", len);
    for (int i = 0; i < len; i++) {
        printf("%02X ", buffer[i]);
    }
    printf("\n");
}

extern "C" bool modem_resp_contains(const char* haystack, const char* needle) {
    if (!haystack || !needle) return false;
    return strstr(haystack, needle) != NULL;
}

extern "C" void modem_print_sanitized(const char* label, const char* str) {
    if (!str) return;
    if (label && strlen(label) > 0) {
        printf("%s: ", label);
    }
    for (int i = 0; str[i] != '\0'; i++) {
        char c = str[i];
        if ((unsigned char)c < 32 && c != '\n' && c != '\r' && c != '\t') {
            putchar(' ');
        } else if ((unsigned char)c > 126) {
            putchar('?');
        } else {
            putchar(c);
        }
    }
    printf("\n");
}



// Embedded Swift Unicode Stubs to satisfy linker when standard library tables are omitted
extern "C" {
    void delay_ms(uint32_t ms) {
        vTaskDelay(pdMS_TO_TICKS(ms));
    }
    bool _swift_stdlib_isInCB_Consonant(uint32_t scalar) { return false; }
    uint8_t _swift_stdlib_getGraphemeBreakProperty(uint32_t scalar) { return 0; }
    uint16_t _swift_stdlib_getNormData(uint32_t scalar) { return 0; }
    uint32_t _swift_stdlib_getComposition(uint32_t a, uint32_t b) { return 0; }
    uint16_t _swift_stdlib_getDecompositionEntry(uint32_t scalar) { return 0; }
    const uint8_t _swift_stdlib_nfd_decompositions[1] = {0};
}



