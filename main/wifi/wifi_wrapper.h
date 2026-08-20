#ifndef WIFI_WRAPPER_H
#define WIFI_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// --- Wi-Fi Station Manager ---
void wifi_manager_init(const char* ssid, const char* password);
bool wifi_manager_is_connected(void);
void wifi_manager_get_ip(char* buffer, int max_len);
void wifi_manager_disconnect(void);
void wifi_manager_reconnect(void);

// --- Native ESP-IDF MQTT Client over Wi-Fi ---
void wifi_mqtt_init(const char* broker_uri, const char* username, const char* password, const char* client_id);
bool wifi_mqtt_is_connected(void);
bool wifi_mqtt_publish(const char* topic, const char* data, int qos);
void wifi_mqtt_stop(void);
void wifi_mqtt_reconnect(void);

// --- Native ESP-IDF SNTP Time Sync over Wi-Fi ---
void wifi_sntp_init(const char* server_name);
bool wifi_sntp_is_synced(void);

#ifdef __cplusplus
}
#endif

#endif // WIFI_WRAPPER_H
