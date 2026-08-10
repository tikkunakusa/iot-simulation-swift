#include "mqtt_wrapper.h"
#include "mqtt_client.h"
#include "esp_log.h"

#include <stdbool.h>

static const char *TAG = "mqtt_wrapper";
static esp_mqtt_client_handle_t s_client = NULL;
static bool s_mqtt_is_connected = false;

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    esp_mqtt_event_handle_t event = event_data;
    switch ((esp_mqtt_event_id_t)event_id) {
        case MQTT_EVENT_CONNECTED:
            s_mqtt_is_connected = true;
            ESP_LOGI(TAG, "MQTT_EVENT_CONNECTED");
            break;
        case MQTT_EVENT_DISCONNECTED:
            s_mqtt_is_connected = false;
            ESP_LOGI(TAG, "MQTT_EVENT_DISCONNECTED");
            break;
        case MQTT_EVENT_PUBLISHED:
            ESP_LOGI(TAG, "MQTT_EVENT_PUBLISHED, msg_id=%d", event->msg_id);
            break;
        case MQTT_EVENT_ERROR:
            s_mqtt_is_connected = false;
            ESP_LOGI(TAG, "MQTT_EVENT_ERROR");
            break;
        default:
            break;
    }
}

bool mqtt_is_connected(void) {
    return s_mqtt_is_connected;
}

void mqtt_init_and_start(const char* broker_uri)
{
    if (s_client != NULL) {
        return; // Already initialized
    }
    
    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = broker_uri,
    };

    s_client = esp_mqtt_client_init(&mqtt_cfg);
    
    if (s_client) {
        esp_mqtt_client_register_event(s_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
        esp_mqtt_client_start(s_client);
    } else {
        ESP_LOGE(TAG, "Failed to initialize MQTT client");
    }
}

void mqtt_publish(const char* topic, const char* data)
{
    if (s_client == NULL) {
        ESP_LOGE(TAG, "MQTT client not initialized");
        return;
    }
    
    // publish with qos=0, retain=0
    int msg_id = esp_mqtt_client_publish(s_client, topic, data, 0, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);
}
