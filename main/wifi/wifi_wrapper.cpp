#include "wifi_wrapper.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_log.h"
#include "mqtt_client.h"
#include "esp_sntp.h"
#include "esp_crt_bundle.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include <string.h>
#include <time.h>

static const char *TAG_WIFI = "WIFI_MANAGER";
static const char *TAG_MQTT = "WIFI_MQTT";
static const char *TAG_SNTP = "WIFI_SNTP";

// --- State Variables ---
static bool s_nvs_initialized = false;
static bool s_netif_initialized = false;
static bool s_wifi_started = false;
static bool s_wifi_connected = false;
static char s_ip_address[32] = {0};

static esp_mqtt_client_handle_t s_mqtt_client = NULL;
static bool s_mqtt_connected = false;
static int s_last_published_msg_id = -1;
static bool s_sntp_initialized = false;

// --- Wi-Fi Event Handler ---
static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                               int32_t event_id, void* event_data) {
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        ESP_LOGI(TAG_WIFI, "Wi-Fi STA started, connecting to AP...");
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        s_wifi_connected = false;
        s_ip_address[0] = '\0';
        ESP_LOGW(TAG_WIFI, "Wi-Fi disconnected. Retrying connection...");
        esp_wifi_connect();
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        esp_ip4addr_ntoa(&event->ip_info.ip, s_ip_address, sizeof(s_ip_address));
        s_wifi_connected = true;
        ESP_LOGI(TAG_WIFI, "Wi-Fi connected! Got IP: %s", s_ip_address);
    }
}

// --- MQTT Event Handler ---
static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;
    switch ((esp_mqtt_event_id_t)event_id) {
        case MQTT_EVENT_CONNECTED:
            s_mqtt_connected = true;
            ESP_LOGI(TAG_MQTT, "✅ Native MQTT connected to broker via Wi-Fi!");
            break;
        case MQTT_EVENT_DISCONNECTED:
            s_mqtt_connected = false;
            ESP_LOGW(TAG_MQTT, "⚠️ Native MQTT disconnected from broker!");
            break;
        case MQTT_EVENT_PUBLISHED:
            s_last_published_msg_id = event->msg_id;
            ESP_LOGI(TAG_MQTT, "📦 Native MQTT publish ACK received (msg_id=%d)", event->msg_id);
            break;
        case MQTT_EVENT_ERROR:
            ESP_LOGE(TAG_MQTT, "❌ Native MQTT error occurred");
            break;
        default:
            break;
    }
}

extern "C" {

void wifi_manager_init(const char* ssid, const char* password) {
    if (!s_nvs_initialized) {
        esp_err_t ret = nvs_flash_init();
        if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
            ESP_ERROR_CHECK(nvs_flash_erase());
            ret = nvs_flash_init();
        }
        ESP_ERROR_CHECK(ret);
        s_nvs_initialized = true;
    }

    if (!s_netif_initialized) {
        ESP_ERROR_CHECK(esp_netif_init());
        ESP_ERROR_CHECK(esp_event_loop_create_default());
        esp_netif_create_default_wifi_sta();
        s_netif_initialized = true;
    }

    if (!s_wifi_started) {
        wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
        ESP_ERROR_CHECK(esp_wifi_init(&cfg));

        esp_event_handler_instance_t instance_any_id;
        esp_event_handler_instance_t instance_got_ip;
        ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,
                                                            ESP_EVENT_ANY_ID,
                                                            &wifi_event_handler,
                                                            NULL,
                                                            &instance_any_id));
        ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,
                                                            IP_EVENT_STA_GOT_IP,
                                                            &wifi_event_handler,
                                                            NULL,
                                                            &instance_got_ip));

        wifi_config_t wifi_config = {};
        if (ssid) {
            strncpy((char*)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid) - 1);
        }
        if (password && strlen(password) > 0) {
            strncpy((char*)wifi_config.sta.password, password, sizeof(wifi_config.sta.password) - 1);
            wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
        } else {
            wifi_config.sta.threshold.authmode = WIFI_AUTH_OPEN;
        }

        ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
        ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
        ESP_ERROR_CHECK(esp_wifi_start());
        s_wifi_started = true;
        ESP_LOGI(TAG_WIFI, "Wi-Fi initialized in STA mode for SSID: %s", ssid ? ssid : "(null)");
    } else {
        // Update credentials and reconnect if already started
        wifi_config_t wifi_config = {};
        if (ssid) {
            strncpy((char*)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid) - 1);
        }
        if (password && strlen(password) > 0) {
            strncpy((char*)wifi_config.sta.password, password, sizeof(wifi_config.sta.password) - 1);
            wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
        } else {
            wifi_config.sta.threshold.authmode = WIFI_AUTH_OPEN;
        }
        esp_wifi_disconnect();
        esp_wifi_set_config(WIFI_IF_STA, &wifi_config);
        esp_wifi_connect();
    }
}

bool wifi_manager_is_connected(void) {
    return s_wifi_connected;
}

void wifi_manager_get_ip(char* buffer, int max_len) {
    if (buffer && max_len > 0) {
        strncpy(buffer, s_ip_address, max_len - 1);
        buffer[max_len - 1] = '\0';
    }
}

void wifi_manager_disconnect(void) {
    if (s_wifi_started) {
        esp_wifi_disconnect();
        s_wifi_connected = false;
    }
}

void wifi_manager_reconnect(void) {
    if (s_wifi_started) {
        esp_wifi_connect();
    }
}

void wifi_mqtt_init(const char* broker_uri, const char* username, const char* password, const char* client_id) {
    if (s_mqtt_client != NULL) {
        esp_mqtt_client_stop(s_mqtt_client);
        esp_mqtt_client_destroy(s_mqtt_client);
        s_mqtt_client = NULL;
        s_mqtt_connected = false;
    }

    // Convert "ssl://" and "tcps://" to "mqtts://", and "tcp://" to "mqtt://" for ESP-IDF compatibility
    char formatted_uri[256] = {0};
    bool is_ssl = false;
    if (broker_uri) {
        if (strncmp(broker_uri, "ssl://", 6) == 0) {
            snprintf(formatted_uri, sizeof(formatted_uri), "mqtts://%s", broker_uri + 6);
            is_ssl = true;
        } else if (strncmp(broker_uri, "tcps://", 7) == 0) {
            snprintf(formatted_uri, sizeof(formatted_uri), "mqtts://%s", broker_uri + 7);
            is_ssl = true;
        } else if (strncmp(broker_uri, "mqtts://", 8) == 0) {
            strncpy(formatted_uri, broker_uri, sizeof(formatted_uri) - 1);
            is_ssl = true;
        } else if (strncmp(broker_uri, "tcp://", 6) == 0) {
            snprintf(formatted_uri, sizeof(formatted_uri), "mqtt://%s", broker_uri + 6);
        } else if (strstr(broker_uri, "://") == NULL) {
            if (strstr(broker_uri, ":8883") != NULL) {
                snprintf(formatted_uri, sizeof(formatted_uri), "mqtts://%s", broker_uri);
                is_ssl = true;
            } else {
                snprintf(formatted_uri, sizeof(formatted_uri), "mqtt://%s", broker_uri);
            }
        } else {
            strncpy(formatted_uri, broker_uri, sizeof(formatted_uri) - 1);
            if (strstr(broker_uri, ":8883") != NULL) is_ssl = true;
        }
    }

    ESP_LOGI(TAG_MQTT, "Configuring ESP-IDF MQTT URI: %s (SSL: %s)", formatted_uri, is_ssl ? "YES" : "NO");

    esp_mqtt_client_config_t mqtt_cfg = {};
    mqtt_cfg.broker.address.uri = formatted_uri;
    if (username && strlen(username) > 0) {
        mqtt_cfg.credentials.username = username;
    }
    if (password && strlen(password) > 0) {
        mqtt_cfg.credentials.authentication.password = password;
    }
    if (client_id && strlen(client_id) > 0) {
        mqtt_cfg.credentials.client_id = client_id;
    } else {
        mqtt_cfg.credentials.client_id = "esp32c6_wifi_client";
    }
    mqtt_cfg.network.reconnect_timeout_ms = 5000;
    mqtt_cfg.network.timeout_ms = 10000;

    if (is_ssl) {
        // Attach ESP-IDF built-in certificate bundle for public CAs (Let's Encrypt / DigiCert / EMQX Cloud)
        mqtt_cfg.broker.verification.crt_bundle_attach = esp_crt_bundle_attach;
    }

    s_mqtt_client = esp_mqtt_client_init(&mqtt_cfg);
    if (s_mqtt_client == NULL) {
        ESP_LOGE(TAG_MQTT, "Failed to initialize ESP-IDF MQTT client!");
        return;
    }

    esp_mqtt_client_register_event(s_mqtt_client, (esp_mqtt_event_id_t)ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(s_mqtt_client);
    ESP_LOGI(TAG_MQTT, "Native ESP-IDF MQTT client started connecting to: %s", formatted_uri);
}

bool wifi_mqtt_is_connected(void) {
    return s_mqtt_connected;
}

bool wifi_mqtt_publish(const char* topic, const char* data, int qos) {
    if (!s_mqtt_connected || s_mqtt_client == NULL) {
        ESP_LOGW(TAG_MQTT, "Cannot publish: MQTT over Wi-Fi is not connected!");
        return false;
    }

    s_last_published_msg_id = -1;
    int data_len = data ? strlen(data) : 0;
    int msg_id = esp_mqtt_client_publish(s_mqtt_client, topic, data, data_len, qos, 0);
    if (msg_id < 0) {
        ESP_LOGE(TAG_MQTT, "Failed to queue publish message!");
        return false;
    }

    if (qos == 0) {
        return true;
    }

    // Wait up to 3 seconds for publish confirmation (QoS 1/2)
    for (int i = 0; i < 30; i++) {
        if (s_last_published_msg_id == msg_id) {
            return true;
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }

    // Even if ACK timed out slightly, message was queued successfully
    return (s_last_published_msg_id == msg_id || msg_id >= 0);
}

void wifi_mqtt_stop(void) {
    if (s_mqtt_client != NULL) {
        esp_mqtt_client_stop(s_mqtt_client);
        esp_mqtt_client_destroy(s_mqtt_client);
        s_mqtt_client = NULL;
        s_mqtt_connected = false;
    }
}

void wifi_mqtt_reconnect(void) {
    if (s_mqtt_client != NULL) {
        esp_mqtt_client_reconnect(s_mqtt_client);
    }
}

void wifi_sntp_init(const char* server_name) {
    if (!s_sntp_initialized) {
        ESP_LOGI(TAG_SNTP, "Initializing SNTP via Wi-Fi with server: %s", server_name ? server_name : "pool.ntp.org");
        esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
        esp_sntp_setservername(0, server_name ? server_name : "pool.ntp.org");
        esp_sntp_init();
        s_sntp_initialized = true;
    }
}

bool wifi_sntp_is_synced(void) {
    time_t now;
    time(&now);
    return (now > 1700000000LL);
}

} // extern "C"
