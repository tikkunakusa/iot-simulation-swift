#ifndef MODEM_WRAPPER_H
#define MODEM_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Modem UART initialization
void modem_init(int rx_pin, int tx_pin, int pwr_pin, int baud_rate);

// Send string command (AT command) to Modem
void modem_send_command(const char* cmd);

// Read response from UART (non-blocking / 200ms timeout)
int modem_read_data(uint8_t* buffer, int buffer_size);

// Read response from UART with custom timeout in milliseconds
int modem_read_data_timeout(uint8_t* buffer, int buffer_size, int timeout_ms);

// Flush incoming UART RX buffer
void modem_flush_rx(void);

// Power cycle / toggle modem via PWRKEY
void modem_power_cycle(int pwr_pin);
void modem_power_pulse(int pwr_pin, int active_low_ms, int wait_boot_ms);

// Signal parsing & status helpers
void parse_modem_csq_if_present(const char* str);
int modem_get_rssi(void);
int modem_get_ber(void);
int modem_get_signal_dbm(void);
bool modem_has_signal(void);
void modem_print_signal_status(void);

// Baud rate and pin dynamic reconfiguration
bool modem_set_baudrate(int baud_rate);
void modem_reconfigure_pins(int rx_pin, int tx_pin);
void modem_print_raw_hex(const uint8_t* buffer, int len);
bool modem_resp_contains(const char* haystack, const char* needle);
void modem_print_sanitized(const char* label, const char* str);

// Delay helper
void delay_ms(uint32_t ms);

#ifdef __cplusplus
}
#endif

#endif // MODEM_WRAPPER_H
