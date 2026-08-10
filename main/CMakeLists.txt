idf_component_register(
	SRCS led_wrapper.cpp wifi_wrapper.c mqtt_wrapper.c sntp_wrapper.c adc_wrapper.c
	PRIV_INCLUDE_DIRS "."
	PRIV_REQUIRES idf_swift esp_driver_gpio led nvs_flash esp_wifi esp_netif esp_event mqtt esp_adc
)

idf_component_register_swift(
	${COMPONENT_LIB}
	BRIDGING_HEADER "${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h"
	SRCS "main.swift" "sensor/dht22.swift" "sensor/led.swift" "sensor/wifi.swift" "sensor/mqtt.swift" "sensor/sntp.swift" "sensor/mq135.swift"
)
