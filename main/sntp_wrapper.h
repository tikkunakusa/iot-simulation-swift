#ifndef SNTP_WRAPPER_H
#define SNTP_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

void sntp_init_client(void);
void sntp_get_time_iso8601(char* buffer, int max_size);

#ifdef __cplusplus
}
#endif

#endif
