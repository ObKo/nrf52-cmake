#include "ch.h"
#include "hal.h"

static THD_WORKING_AREA(testThreadWA, 256);
static THD_FUNCTION(testThread, arg) {
    (void)arg;

    while (true) {
        osalThreadSleepMilliseconds(250);
        palToggleLine(LINE_LED_1);
    }
}

int main(void) {
    halInit();
    chSysInit();

    chThdCreateStatic(testThreadWA,
            sizeof(testThreadWA),
            NORMALPRIO,
            testThread,
            NULL);

    for(;;)
        osalThreadSleepMilliseconds(1000);
        
    return 0;
}
