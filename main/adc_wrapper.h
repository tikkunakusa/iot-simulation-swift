#ifndef ADC_WRAPPER_H
#define ADC_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

void adc_init_channel(int channel);
int adc_read_channel(int channel);

#ifdef __cplusplus
}
#endif

#endif // ADC_WRAPPER_H
