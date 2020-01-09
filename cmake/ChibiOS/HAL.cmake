set(HAL_COMPONENTS MMCSD ADC CAN CRYPTO DAC GPT I2C I2S ICU MAC MMC_SPI PAL PWM RTC SDC SERIAL SERIAL_USB SIO SPI TRNG UART USB WDG WSPI)
set(HAL_CONTRIB_COMPONENTS NAND SRAM SDRAM ONEWIRE EICU CRC RNG EE24XX EE25XX EEPROM TIMCAP QEI USB_HID USB_MSD COMP OPAMP)

if(NOT ChibiOS_DIR)
    return()
endif()

if (NOT ("HAL" IN_LIST ChibiOS_FIND_COMPONENTS))
    return()
endif()

find_path(ChibiOS_HAL_INCLUDE_DIR
    NAMES hal.h
    PATHS ${ChibiOS_DIR}/os/hal/include
)
if(ChibiOS_HAL_INCLUDE_DIR)
    set(ChibiOS_HAL_FOUND TRUE)
endif()

add_library(ChibiOS::HAL INTERFACE IMPORTED)
target_sources(ChibiOS::HAL INTERFACE 
    ${ChibiOS_DIR}/os/hal/src/hal.c 
    ${ChibiOS_DIR}/os/hal/src/hal_buffers.c 
    ${ChibiOS_DIR}/os/hal/src/hal_queues.c 
    ${ChibiOS_DIR}/os/hal/src/hal_st.c 
)
target_include_directories(ChibiOS::HAL INTERFACE 
    ${ChibiOS_DIR}/os/hal/include
)

add_library(ChibiOS::HAL::ARMCortexM4 INTERFACE IMPORTED)
target_sources(ChibiOS::HAL::ARMCortexM4 INTERFACE 
    ${ChibiOS_DIR}/os/hal/ports/common/ARMCMx/nvic.c
)
target_include_directories(ChibiOS::HAL::ARMCortexM4 INTERFACE 
    ${ChibiOS_DIR}/os/hal/ports/common/ARMCMx
)

foreach(COMP IN LISTS HAL_COMPONENTS)
    string(TOLOWER ${COMP} COMP_L)
    add_library(ChibiOS::HAL::${COMP} INTERFACE IMPORTED)
    target_sources(ChibiOS::HAL::${COMP} INTERFACE ${ChibiOS_DIR}/os/hal/src/hal_${COMP_L}.c)
    target_link_libraries(ChibiOS::HAL::${COMP} INTERFACE ChibiOS::HAL)
endforeach()

if(ChibiOS_Contrib_DIR)
    add_library(ChibiOS::HAL::Contrib INTERFACE IMPORTED)
    target_sources(ChibiOS::HAL::Contrib INTERFACE 
        ${ChibiOS_Contrib_DIR}/os/hal/src/hal_community.c
    )
    target_include_directories(ChibiOS::HAL::Contrib INTERFACE 
        ${ChibiOS_Contrib_DIR}/os/hal/include
    )
    target_link_libraries(ChibiOS::HAL::Contrib INTERFACE ChibiOS::HAL)
    
    foreach(COMP IN LISTS HAL_CONTRIB_COMPONENTS)
        string(TOLOWER ${COMP} COMP_L)
        add_library(ChibiOS::HAL::${COMP} INTERFACE IMPORTED)
        target_sources(ChibiOS::HAL::${COMP} INTERFACE ${ChibiOS_Contrib_DIR}/os/hal/src/hal_${COMP_L}.c)
        target_link_libraries(ChibiOS::HAL::${COMP} INTERFACE ChibiOS::HAL::Contrib)
    endforeach()
endif()

function(ChibiOS_HAL_link_libraries TARGET)
    cmake_parse_arguments(HAL "" "PLATFORM" "CONFIG" ${ARGN})
    if(NOT HAL_CONFIG)
        return()
    endif()
    
    set(HAL_COMPS)

    foreach(CONF IN LISTS HAL_CONFIG)
        file(STRINGS "${CONF}" CONF_STRINGS REGEX "#define[ \t]+HAL_USE_[a-zA-Z0-9]+[ \t]+TRUE")
        foreach(STR IN LISTS CONF_STRINGS)
            string(REGEX MATCH "HAL_USE_([a-zA-Z0-9]+)[ \t]+TRUE" MATCHED ${STR})
            if(CMAKE_MATCH_1 AND (NOT ${CMAKE_MATCH_1} STREQUAL "COMMUNITY"))
                list(APPEND HAL_COMPS ${CMAKE_MATCH_1})
            endif()
        endforeach()
    endforeach()
    message(STATUS "Detected ChibiOS HAL components: ${HAL_COMPS}")
    
    foreach(COMP IN LISTS HAL_COMPS)
        target_link_libraries(${TARGET} PRIVATE ChibiOS::HAL::${COMP})
    endforeach()
    target_link_libraries(${TARGET} PRIVATE ChibiOS::HAL)
    if(HAL_PLATFORM)
        foreach(COMP IN LISTS HAL_COMPS)
            target_link_libraries(${TARGET} PRIVATE ChibiOS::HAL::${HAL_PLATFORM}::${COMP})
        endforeach()
        target_link_libraries(${TARGET} PRIVATE ChibiOS::HAL::${HAL_PLATFORM})
    endif()
endfunction()
