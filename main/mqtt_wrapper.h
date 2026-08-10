#ifndef MQTT_WRAPPER_H
#define MQTT_WRAPPER_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void mqtt_init_and_start(const char* broker_uri);
void mqtt_publish(const char* topic, const char* data);
bool mqtt_is_connected(void);

#ifdef __cplusplus
}
#endif

#endif
