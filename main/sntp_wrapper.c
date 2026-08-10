#include "sntp_wrapper.h"
#include "esp_sntp.h"
#include <time.h>

void sntp_init_client(void) {
    esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
    esp_sntp_setservername(0, "pool.ntp.org");
    esp_sntp_init();
}

void sntp_get_time_iso8601(char* buffer, int max_size) {
    time_t now;
    struct tm timeinfo;
    time(&now);
    
    gmtime_r(&now, &timeinfo);
    
    // If time isn't synced yet, it defaults to ~1970
    strftime(buffer, max_size, "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
}
