function(nrf52_linker_sizes_from_device CHIP VARIANT RAM_SIZE FLASH_SIZE)
    if(${CHIP} EQUAL 840)
        set(${RAM_SIZE} 65536 PARENT_SCOPE)
        set(${FLASH_SIZE} 1048576 PARENT_SCOPE)
    elseif(${CHIP} EQUAL 832)
        if(${VARIANT} STREQUAL "AB")
            set(${RAM_SIZE} 65536 PARENT_SCOPE)
            set(${FLASH_SIZE} 524288 PARENT_SCOPE)
        else()
            set(${RAM_SIZE} 32768 PARENT_SCOPE)
            set(${FLASH_SIZE} 262144 PARENT_SCOPE)
        endif()
    elseif(${CHIP} EQUAL 811)
        set(${RAM_SIZE} 24576 PARENT_SCOPE)
        set(${FLASH_SIZE} 196608 PARENT_SCOPE)
    elseif(${CHIP} EQUAL 810)
        set(${RAM_SIZE} 24576 PARENT_SCOPE)
        set(${FLASH_SIZE} 196608 PARENT_SCOPE)
    endif()
endfunction()

function(nrf52_linker_generate_script TARGET LINKER_SCRIPT)
    cmake_parse_arguments(LINKER "" "RAM_SIZE;FLASH_SIZE;RAM_START;FLASH_START" "" ${ARGN})
    
    nrf52_get_chip(${TARGET} NRF52_CHIP NRF52_CHIP_VARIANT)
    nrf52_linker_sizes_from_device(${NRF52_CHIP} ${NRF52_CHIP_VARIANT} DEFAULT_RAM DEFAULT_FLASH)
    
    if(NOT LINKER_RAM_SIZE)
        set(LINKER_RAM_SIZE ${DEFAULT_RAM})
    endif()
    if(NOT LINKER_FLASH_SIZE)
        set(LINKER_FLASH_SIZE ${DEFAULT_FLASH})
    endif()
    if(NOT LINKER_RAM_START)
        set(LINKER_RAM_START 536870912)
    endif()
    if(NOT LINKER_FLASH_START)
        set(LINKER_FLASH_START 0)
    endif()
    
    if(${CMAKE_VERSION} VERSION_GREATER "3.13.0")
        math(EXPR LINKER_FLASH_SIZE "${LINKER_FLASH_SIZE}" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR LINKER_RAM_SIZE "${LINKER_RAM_SIZE}" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR LINKER_FLASH_START "${LINKER_FLASH_START}" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR LINKER_RAM_START "${LINKER_RAM_START}" OUTPUT_FORMAT HEXADECIMAL)
    endif()
    
    set(LINKER_SCRIPT_SRC
        "MEMORY\n"
        "{\n"
        "    FLASH (rx) : ORIGIN = ${LINKER_FLASH_START}, LENGTH = ${LINKER_FLASH_SIZE}\n"
        "    RAM (rwx) :  ORIGIN = ${LINKER_RAM_START}, LENGTH = ${LINKER_RAM_SIZE}\n"
        "}\n"
        "INCLUDE \"nrf_common.ld\"\n"
    )
    file(WRITE ${LINKER_SCRIPT} ${LINKER_SCRIPT_SRC})
endfunction()
