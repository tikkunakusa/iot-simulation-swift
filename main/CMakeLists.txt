idf_component_register(
	SRCS "sensors/gps/gps_wrapper.cpp" "sensors/modem_4g/modem_wrapper.cpp"
	PRIV_INCLUDE_DIRS "."
	PRIV_REQUIRES idf_swift esp_driver_gpio esp_driver_uart esp_tinygpsplusplus
)

idf_component_register_swift(
	${COMPONENT_LIB}
	BRIDGING_HEADER "${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h"
	SRCS "main.swift" "sensors/dht22/dht22.swift" "sensors/gps/tinygpsplus.swift" "sensors/modem_4g/modem.swift" "sensors/led/led.swift" "mqtt/mqtt.swift" "mqtt/sntp/sntp.swift" "transmissions/DataManager.swift"
)
