#ifndef GPS_WRAPPER_H
#define GPS_WRAPPER_H

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* gps_handle_t;

gps_handle_t gps_init(void);
void gps_free(gps_handle_t handle);
void gps_update(gps_handle_t handle);
bool gps_encode(gps_handle_t handle, char c);
bool gps_location_is_valid(gps_handle_t handle);
double gps_location_lat(gps_handle_t handle);
double gps_location_lng(gps_handle_t handle);
uint32_t gps_location_age(gps_handle_t handle);

uint32_t gps_chars_processed(gps_handle_t handle);
uint32_t gps_passed_checksum(gps_handle_t handle);
uint32_t gps_failed_checksum(gps_handle_t handle);
uint32_t gps_satellites_value(gps_handle_t handle);

// Hardware UART interface for GPS Neo-6M
void gps_uart_init(int tx_pin, int rx_pin, int baud_rate);
void print_gps_location(double lat, double lng);
void print_gps_status(gps_handle_t handle);

#ifdef __cplusplus
}
#endif

#endif // GPS_WRAPPER_H
