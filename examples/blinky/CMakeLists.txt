set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/nrf52.cmake)
cmake_minimum_required(VERSION 3.8)

project(blinky C ASM)

add_executable(blinky-poll blinky-poll.c)
set_target_properties(blinky-poll PROPERTIES NRF52_CHIP NRF52832-QFAB)
nrf52_target(blinky-poll)

add_executable(blinky-irq blinky-irq.c)
set_target_properties(blinky-irq PROPERTIES NRF52_CHIP NRF52832-QFAB)
nrf52_target(blinky-irq)
