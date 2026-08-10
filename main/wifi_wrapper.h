#ifndef WIFI_WRAPPER_H
#define WIFI_WRAPPER_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void wifi_init_sta(const char* ssid, const char* pass);
bool wifi_is_connected(void);

#ifdef __cplusplus
}
#endif


#endif
