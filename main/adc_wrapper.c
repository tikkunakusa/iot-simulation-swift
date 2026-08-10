#include "adc_wrapper.h"
#include "esp_adc/adc_oneshot.h"

static adc_oneshot_unit_handle_t adc1_handle = NULL;

void adc_init_channel(int channel) {
    printf("Initializing ADC on channel %d\n", channel);
    if (adc1_handle == NULL) {
        adc_oneshot_unit_init_cfg_t init_config1 = {
            .unit_id = ADC_UNIT_1,
        };
        esp_err_t ret = adc_oneshot_new_unit(&init_config1, &adc1_handle);
        printf("adc_oneshot_new_unit returned %d\n", ret);
        if (ret != ESP_OK) return;
    }
    adc_oneshot_chan_cfg_t config = {
        .bitwidth = ADC_BITWIDTH_DEFAULT,
        .atten = ADC_ATTEN_DB_12,
    };
    esp_err_t ret = adc_oneshot_config_channel(adc1_handle, (adc_channel_t)channel, &config);
    printf("adc_oneshot_config_channel returned %d\n", ret);
}

int adc_read_channel(int channel) {
    int out_raw = 0;
    if (adc1_handle != NULL) {
        adc_oneshot_read(adc1_handle, (adc_channel_t)channel, &out_raw);
    }
    return out_raw;
}
