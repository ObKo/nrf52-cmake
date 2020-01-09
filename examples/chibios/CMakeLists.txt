get_filename_component(NRF52_CMAKE_PATH "${CMAKE_SOURCE_DIR}/../../cmake" ABSOLUTE)
set(CMAKE_TOOLCHAIN_FILE "${NRF52_CMAKE_PATH}/nrf52.cmake")
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${NRF52_CMAKE_PATH}")

message(${CMAKE_MODULE_PATH})
cmake_minimum_required(VERSION 3.12)

project(meteo C ASM)

find_package(ChibiOS 19.1 COMPONENTS Core HAL NRF5 REQUIRED)

add_executable(meteo board.c main.c)
set_target_properties(meteo PROPERTIES
    NRF52_CHIP NRF52832-QFAA
    NRF52_NO_LINKER_SCRIPT YES
    NRF52_NO_SDK YES
)
nrf52_target(meteo)
target_include_directories(meteo PRIVATE ${CMAKE_SOURCE_DIR})
target_link_libraries(meteo PRIVATE ChibiOS::RT ChibiOS::NRF52832)
ChibiOS_set_stack_sizes(meteo DEFAULT)
ChibiOS_HAL_link_libraries(meteo PLATFORM NRF52832 CONFIG halconf.h halconf_community.h)
target_compile_definitions(meteo PRIVATE -DCORTEX_USE_FPU=TRUE)
target_link_options(meteo PRIVATE -T "${CMAKE_SOURCE_DIR}/NRF52832.ld")
