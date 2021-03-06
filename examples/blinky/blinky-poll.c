#include <nrf.h>

#define BLINKY_PIN 30       // LED GPIO on some chinese shield

int main()
{
    NRF_TIMER0->SHORTS = TIMER_SHORTS_COMPARE0_CLEAR_Msk;
    NRF_TIMER0->MODE = TIMER_MODE_MODE_Timer;
    NRF_TIMER0->BITMODE = TIMER_BITMODE_BITMODE_16Bit;
    NRF_TIMER0->PRESCALER = 7; // 125 kHz
    NRF_TIMER0->CC[0] = 62500; // 2 Hz
    NRF_TIMER0->EVENTS_COMPARE[0] = 0;
    NRF_TIMER0->TASKS_START = 1;

    NRF_GPIO->DIRSET = (1 << BLINKY_PIN);
    NRF_GPIO->OUTSET = (1 << BLINKY_PIN);

    for(;;)
    {
        while (!NRF_TIMER0->EVENTS_COMPARE[0]);
        NRF_TIMER0->EVENTS_COMPARE[0] = 0;

        NRF_GPIO->OUTCLR = (1 << BLINKY_PIN);

        while (!NRF_TIMER0->EVENTS_COMPARE[0]);
        NRF_TIMER0->EVENTS_COMPARE[0] = 0;

        NRF_GPIO->OUTSET = (1 << BLINKY_PIN);
    }

    return 0;
}
