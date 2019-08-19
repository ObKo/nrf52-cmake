#include <nrf.h>

#define BLINKY_PIN 30       // LED GPIO on some chinese shield

void TIMER0_IRQHandler(void)
{
    NRF_TIMER0->EVENTS_COMPARE[0] = 0;
    if (NRF_GPIO->OUT & (1 << BLINKY_PIN))
        NRF_GPIO->OUTCLR = (1 << BLINKY_PIN);
    else
        NRF_GPIO->OUTSET = (1 << BLINKY_PIN);
}

int main()
{
    NRF_GPIO->DIRSET = (1 << BLINKY_PIN);

    NRF_TIMER0->SHORTS = TIMER_SHORTS_COMPARE0_CLEAR_Msk;
    NRF_TIMER0->MODE = TIMER_MODE_MODE_Timer;
    NRF_TIMER0->BITMODE = TIMER_BITMODE_BITMODE_16Bit;
    NRF_TIMER0->PRESCALER = 7; // 125 kHz
    NRF_TIMER0->CC[0] = 62500; // 2 Hz
    NRF_TIMER0->EVENTS_COMPARE[0] = 0;
    NRF_TIMER0->INTENSET = TIMER_INTENSET_COMPARE0_Msk;
    NRF_TIMER0->TASKS_START = 1;

    NVIC_EnableIRQ(TIMER0_IRQn);

    for(;;)
        __WFI();

    return 0;
}
