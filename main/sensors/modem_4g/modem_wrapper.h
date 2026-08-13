#ifndef MODEM_WRAPPER_H
#define MODEM_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Inisialisasi UART Modem
void modem_init(int rx_pin, int tx_pin, int pwr_pin, int baud_rate);

// Mengirim string command (AT command) ke Modem
void modem_send_command(const char* cmd);

// Membaca respon dari UART (non-blocking / timeout singkat)
// Mengembalikan panjang bytes yang terbaca
int modem_read_data(uint8_t* buffer, int buffer_size);

// Merestart modem melalui PWRKEY
void modem_power_cycle(int pwr_pin);

// Helper for formatting float/double to string in Embedded Swift
void format_double_to_string(double val, char* buffer, int max_len);
void format_float_to_string(float val, char* buffer, int max_len);

// Helper for Epoch Time (SNTP / System Clock)
int64_t get_epoch_timestamp(void);
void set_epoch_timestamp(int64_t epoch_sec);
void parse_modem_time_if_present(const char* str);
void parse_modem_gnss_if_present(const char* str);
bool modem_gnss_has_fix(void);
double modem_gnss_get_latitude(void);
double modem_gnss_get_longitude(void);
void delay_ms(uint32_t ms);

#ifdef __cplusplus
}
#endif

#endif // MODEM_WRAPPER_H
