set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/nrf52.cmake)
cmake_minimum_required(VERSION 3.8)

project(ble C ASM)

find_package(SoftDevice COMPONENTS S132 REQUIRED)

add_executable(ble ble.c)
set_target_properties(ble PROPERTIES
    NRF52_CHIP NRF52832-QFAA
    SOFTDEVICE S132
    CUSTOM_LINKER_SCRIPT YES
)
nrf52_target(ble)
nrf52_add_linker_script(ble ${CMAKE_CURRENT_SOURCE_DIR}/ble.ld)

target_link_libraries(ble PRIVATE SoftDevice::S132)

nrf52_add_softdevice_target(softdevice SOFTDEVICE S132)
