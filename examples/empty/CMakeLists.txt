set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../nrf52.cmake)
cmake_minimum_required(VERSION 3.8)

project(empty C ASM)

add_executable(empty main.c)
set_target_properties(empty PROPERTIES NRF52_CHIP NRF52832)
nrf52_target(empty)
