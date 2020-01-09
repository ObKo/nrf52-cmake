set(NRF52832_HAL_COMPONENTS GPT I2C ICU PAL PWM QEI RNG SERIAL SPI WDG)
set(NRF52832_HAL_LLD_DRIVERS TIMERv1 TWIMv1 TIMERv1 GPIOv1 PWMv2 QDECv1 RNGv1 UARTv1 SPIv1 WDTv1)

if(NOT ChibiOS_DIR)
    return()
endif()

if(NOT ChibiOS_Contrib_DIR)
    return()
endif()

if (NOT ("NRF5" IN_LIST ChibiOS_FIND_COMPONENTS))
    return()
endif()

set(ChibiOS_NRF5_FOUND TRUE)

add_library(ChibiOS::NRF52832 INTERFACE IMPORTED)
target_include_directories(ChibiOS::NRF52832 INTERFACE 
    ${ChibiOS_Contrib_DIR}/os/common/startup/ARMCMx/devices/NRF52832
)
target_link_libraries(ChibiOS::NRF52832 INTERFACE ChibiOS::ARMCortexM4)

add_library(ChibiOS::HAL::NRF52832 INTERFACE IMPORTED)
target_sources(ChibiOS::HAL::NRF52832 INTERFACE 
    ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/NRF52832/hal_lld.c
    ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/NRF52832/nrf52_isr.c
    ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/LLD/TIMERv1/hal_st_lld.c
)
target_include_directories(ChibiOS::HAL::NRF52832 INTERFACE 
    ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/LLD
    ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/NRF52832
    ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/LLD/TIMERv1
)
target_link_libraries(ChibiOS::HAL::NRF52832 INTERFACE ChibiOS::HAL)
target_link_libraries(ChibiOS::HAL::NRF52832 INTERFACE ChibiOS::HAL::ARMCortexM4)
target_link_libraries(ChibiOS::HAL::NRF52832 INTERFACE ChibiOS::HAL::Contrib)

set(INDEX 0)
foreach(COMP IN LISTS NRF52832_HAL_COMPONENTS)
    list(GET NRF52832_HAL_LLD_DRIVERS ${INDEX} LLD_DRIVER)
    string(TOLOWER ${COMP} COMP_L)
    
    add_library(ChibiOS::HAL::NRF52832::${COMP} INTERFACE IMPORTED)
    target_sources(ChibiOS::HAL::NRF52832::${COMP} INTERFACE ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/LLD/${LLD_DRIVER}/hal_${COMP_L}_lld.c)
    target_include_directories(ChibiOS::HAL::NRF52832::${COMP} INTERFACE ${ChibiOS_Contrib_DIR}/os/hal/ports/NRF5/LLD/${LLD_DRIVER})
    target_link_libraries(ChibiOS::HAL::NRF52832::${COMP} INTERFACE ChibiOS::HAL::${COMP})
    target_link_libraries(ChibiOS::HAL::NRF52832::${COMP} INTERFACE ChibiOS::HAL::NRF52832)
    
    math(EXPR INDEX "${INDEX} + 1")
endforeach()
