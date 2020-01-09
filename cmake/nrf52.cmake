get_filename_component(NRF52_CMAKE_DIR ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
list(APPEND CMAKE_MODULE_PATH ${NRF52_CMAKE_DIR})

set(NRF52_SUPPORTED_DEVICES 840 832 811 810)

if(NOT TOOLCHAIN_PATH)
     set(TOOLCHAIN_PATH "/usr")
     message(STATUS "No TOOLCHAIN_PATH specified, using default: " ${TOOLCHAIN_PATH})
else()
     file(TO_CMAKE_PATH "${TOOLCHAIN_PATH}" TOOLCHAIN_PATH)
endif()

if(NOT TOOLCHAIN_TRIPLET)
    set(TOOLCHAIN_TRIPLET "arm-none-eabi")
    message(STATUS "No TOOLCHAIN_TRIPLET specified, using default: " ${TOOLCHAIN_TRIPLET})
endif()


if(NOT NRF5_SDK_PATH)
     set(NRF5_SDK_PATH "/opt/nRF5_SDK")
     message(STATUS "No NRF5_SDK_PATH specified, using default: " ${NRF5_SDK_PATH})
else()
     file(TO_CMAKE_PATH "${NRF5_SDK_PATH}" NRF5_SDK_PATH)
endif()

include(nrf52-linker)

set(TOOLCHAIN_BIN_PATH "${TOOLCHAIN_PREFIX}/bin")
set(TOOLCHAIN_INC_PATH "${TOOLCHAIN_PREFIX}/${TOOLCHAIN_TRIPLET}/include")
set(TOOLCHAIN_LIB_PATH "${TOOLCHAIN_PREFIX}/${TOOLCHAIN_TRIPLET}/lib")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_C_COMPILER "${TOOLCHAIN_BIN_PATH}/${TOOLCHAIN_TRIPLET}-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_BIN_PATH}/${TOOLCHAIN_TRIPLET}-g++")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_BIN_PATH}/${TOOLCHAIN_TRIPLET}-gcc")

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

function(nrf52_get_chip TARGET CHIP VARIANT)
    get_target_property(NRF52_CHIP_TARGET ${TARGET} NRF52_CHIP)
    string(TOUPPER ${NRF52_CHIP_TARGET} NRF52_CHIP_TARGET)
    
    if(NOT NRF52_CHIP_TARGET)
        message(FATAL_ERROR "Please specify NRF52 chip for target ${TARGET} using NRF52_CHIP property")
    endif()
    
    string(REGEX MATCH "^NRF52([0-9]+)(\\-[A-Z][A-Z]([A-Z][A-Z]))?$" NRF52_CHIP_TARGET ${NRF52_CHIP_TARGET})
    set(NRF52_CHIP ${CMAKE_MATCH_1})
    if(CMAKE_MATCH_3)
        set(NRF52_VARIANT ${CMAKE_MATCH_3})
    else()
        set(NRF52_VARIANT AA)
    endif()
    
    list(FIND NRF52_SUPPORTED_DEVICES ${NRF52_CHIP} NRF52_CHIP_INDEX)
    if (NRF52_CHIP_INDEX EQUAL -1)
        message(FATAL_ERROR "Unknown chip ${NRF52_CHIP_TARGET}")
    endif()
        
    set(${CHIP} ${NRF52_CHIP} PARENT_SCOPE)
    set(${VARIANT} ${NRF52_VARIANT} PARENT_SCOPE)
endfunction()

function(nrf52_add_sdk_startup TARGET)
    get_target_property(TARGET_NO_SDK ${TARGET} NRF52_NO_SDK)
    if(TARGET_NO_SDK)
        return()
    endif()

    target_include_directories(${TARGET} PRIVATE "${NRF5_SDK_PATH}/components/toolchain/cmsis/include")
    target_include_directories(${TARGET} PRIVATE "${NRF5_SDK_PATH}/modules/nrfx/mdk")
    
    nrf52_get_chip(${TARGET} NRF52_CHIP NRF52_CHIP_VARIANT)
    
    unset(NRF52_STARTUP_FILE CACHE)
    find_file(NRF52_STARTUP_FILE
        NAMES gcc_startup_nrf52${NRF52_CHIP}.S gcc_startup_nrf52.S
        PATHS "${NRF5_SDK_PATH}/modules/nrfx/mdk"
        NO_DEFAULT_PATH
    )
    
    unset(NRF52_SYSTEM_FILE CACHE)
    find_file(NRF52_SYSTEM_FILE
        NAMES system_nrf52${NRF52_CHIP}.c system_nrf52.c
        PATHS "${NRF5_SDK_PATH}/modules/nrfx/mdk"
        NO_DEFAULT_PATH
    )
    
    if((NOT NRF52_STARTUP_FILE) OR (NOT NRF52_SYSTEM_FILE))
        message(WARNING "Cannot find startup sources for target ${TARGET}, check NRF5_SDK_PATH variable")
    else()
        target_sources(${TARGET} PRIVATE "${NRF52_STARTUP_FILE}" "${NRF52_SYSTEM_FILE}")
    endif()
endfunction()

function(nrf52_add_linker_script TARGET SCRIPT)
    target_link_options(${TARGET} PRIVATE -T "${SCRIPT}")
    target_link_options(${TARGET} PRIVATE -L "${NRF5_SDK_PATH}/modules/nrfx/mdk")
endfunction()

function(nrf52_generate_linker_script TARGET)
    get_target_property(TARGET_NO_LINKER_SCRIPT ${TARGET} NRF52_NO_LINKER_SCRIPT)
    if(TARGET_NO_LINKER_SCRIPT)
        return()
    endif()
    set(NRF52_LINKER_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.ld)
    nrf52_linker_generate_script(${TARGET} "${NRF52_LINKER_FILE}")
    nrf52_add_linker_script(${TARGET} "${NRF52_LINKER_FILE}")
endfunction()

function(nrf52_configure_compiler TARGET)
    nrf52_get_chip(${TARGET} NRF52_CHIP NRF52_CHIP_VARIANT)
    
    if(NRF52_CHIP EQUAL 840)
        target_compile_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16)
        target_compile_definitions(${TARGET} PRIVATE -DFLOAT_ABI_HARD)
        target_link_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16)
    elseif(NRF52_CHIP EQUAL 832)
        target_compile_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16)
        target_link_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16)
        target_compile_definitions(${TARGET} PRIVATE -DFLOAT_ABI_HARD)
    elseif(NRF52_CHIP EQUAL 811)
        target_compile_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=soft)
        target_compile_definitions(${TARGET} PRIVATE -DFLOAT_ABI_SOFT)
        target_link_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=soft)
    elseif(NRF52_CHIP EQUAL 810)
        target_compile_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=soft)
        target_compile_definitions(${TARGET} PRIVATE -DFLOAT_ABI_SOFT)
        target_link_options(${TARGET} PRIVATE -mcpu=cortex-m4 -mfloat-abi=soft)
    endif()
    
    target_compile_options(${TARGET} PRIVATE -mthumb -mabi=aapcs -Wall -ffunction-sections -fdata-sections -fno-strict-aliasing -fno-builtin -fshort-enums $<$<CONFIG:Release>:-Os -flto>)
    target_compile_definitions(${TARGET} PRIVATE -DNRF52${NRF52_CHIP}_XX${NRF52_CHIP_VARIANT})
    target_link_options(${TARGET} PRIVATE -mthumb -mabi=aapcs -Wl,--gc-sections --specs=nano.specs $<$<CONFIG:Release>:-Os -flto>)
endfunction()

function(nrf52_target TARGET)
    get_target_property(TARGET_TYPE ${TARGET} TYPE)    
    nrf52_configure_compiler(${TARGET})
    if(TARGET_TYPE STREQUAL EXECUTABLE)
        nrf52_add_sdk_startup(${TARGET})
        nrf52_generate_linker_script(${TARGET})
        target_link_libraries(${TARGET} PRIVATE -lc -lnosys -lm)
    endif()
endfunction()
