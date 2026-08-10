idf_component_register(
	SRCS "sensor/gps_wrapper.cpp"
	PRIV_INCLUDE_DIRS "."
	PRIV_REQUIRES idf_swift esp_driver_gpio esp_driver_uart esp_tinygpsplusplus
)

idf_component_register_swift(
	${COMPONENT_LIB}
	BRIDGING_HEADER "${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h"
	SRCS "main.swift" "sensor/dht22.swift" "sensor/tinygpsplus.swift"
)
