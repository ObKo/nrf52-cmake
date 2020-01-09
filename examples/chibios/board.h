/*
    Copyright (C) 2016 Stephane D'Alu

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#ifndef _BOARD_H_
#define _BOARD_H_

/* Board identifier. */
#define BOARD_NRF52_SHIELD
#define BOARD_NAME             "nRF52 Shield"

#define NRF5_XTAL_VALUE        32000000
#define NRF5_LFCLK_SOURCE      1


#define IOPORT1_LED_1          30U
#define IOPORT1_LED_2          31U

#define IOPORT1_BUTTON_1       4

/*
 * IO lines assignments.
 */
/* Board defined */
#define LINE_LED_1     PAL_LINE(IOPORT1, IOPORT1_LED_1)
#define LINE_LED_2     PAL_LINE(IOPORT1, IOPORT1_LED_2)

#define LINE_BUTTON_1  PAL_LINE(IOPORT1, IOPORT1_BUTTON_1)

#if !defined(_FROM_ASM_)
#ifdef __cplusplus
extern "C" {
#endif
  void boardInit(void);
#ifdef __cplusplus
}
#endif
#endif /* _FROM_ASM_ */

#endif /* _BOARD_H_ */
