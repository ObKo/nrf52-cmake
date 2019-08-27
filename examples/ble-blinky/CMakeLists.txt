set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/nrf52.cmake)
cmake_minimum_required(VERSION 3.8)

project(ble-blinky C ASM)

find_package(SoftDevice COMPONENTS S132 REQUIRED)

add_executable(ble-blinky ble-blinky.c)
set_target_properties(ble-blinky PROPERTIES
    NRF52_CHIP NRF52832-QFAA
    NRF52_NO_LINKER_SCRIPT YES
)
target_link_libraries(ble-blinky PRIVATE SoftDevice::S132)
nrf52_target(ble-blinky)
softdevice_generate_linker_script(ble-blinky SOFTDEVICE S132 RAM 0x2600)

# Add custom make target for flashing SoftDevice firmware
softdevice_add_flash_target(softdevice FIRMWARE ${SoftDevice_S132_FIRMWARE})
