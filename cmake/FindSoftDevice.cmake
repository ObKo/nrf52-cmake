if(NOT SoftDevice_FIND_COMPONENTS)
    set(SoftDevice_FIND_COMPONENTS S112;S132;S140)
endif()

set(SoftDevice_INCLUDE_DIRS)

macro(nrf52_sd_parse_headers COMP)
    file(STRINGS "${SoftDevice_${COMP}_CONFIG_HEADER}" VERSION_STRINGS REGEX "#define SD_(MAJOR)|(MINOR)|(BUGFIX)_VERSION")
    foreach(STRING ${VERSION_STRINGS})
        string(REGEX MATCH "SD_((MAJOR)|(MINOR)|(BUGFIX))_VERSION +\\(([0-9]+)\\)" MATCHED ${STRING})
        if(MATCHED)
            set(SoftDevice_${COMP}_VERSION_${CMAKE_MATCH_1} ${CMAKE_MATCH_5})
        endif()
    endforeach()
    set(SoftDevice_${COMP}_VERSION "${SoftDevice_${COMP}_VERSION_MAJOR}.${SoftDevice_${COMP}_VERSION_MINOR}.${SoftDevice_${COMP}_VERSION_BUGFIX}")

    file(STRINGS "${SoftDevice_${COMP}_CONFIG_HEADER}" SD_FLASH_SIZE_STRING REGEX "#define SD_FLASH_SIZE")
    string(REGEX MATCH "SD_FLASH_SIZE +\\(?((0x)?[0-9]+)\\)?" MATCHED ${SD_FLASH_SIZE_STRING})
    set(SD_FLASH_SIZE ${CMAKE_MATCH_1})

    file(STRINGS "${SoftDevice_${COMP}_MBR_HEADER}" MBR_SIZE_STRING REGEX "#define MBR_SIZE")
    string(REGEX MATCH "MBR_SIZE +\\(?((0x)?[0-9]+)\\)?" MATCHED ${MBR_SIZE_STRING})
    set(SD_MBR_SIZE ${CMAKE_MATCH_1})

    math(EXPR SoftDevice_${COMP}_SIZE "${SD_FLASH_SIZE} + ${SD_MBR_SIZE}")
endmacro()

function(SoftDevice_add_flash_target TARGET)
    cmake_parse_arguments(SoftDevice "" "ADAPTER;FIRMWARE" "" ${ARGN})
    if(NOT SoftDevice_ADAPTER)
        set(SoftDevice_ADAPTER jlink)
        message(STATUS "No ADAPTER specified using defalut adapter \"${SoftDevice_ADAPTER}\"")
    endif()
    if(NOT SoftDevice_FIRMWARE)
        message(FATAL_ERROR "SoftDevice firmware file must be specified")
    endif()

    find_program(SoftDevice_OPENOCD openocd)
    if(NOT SoftDevice_OPENOCD)
        message(FATAL_ERROR "Cannot find openocd executable")
    endif()

    set(OPENOCD_ARGS
        -f "interface/${SoftDevice_ADAPTER}.cfg"
        -c "transport select swd"
        -f "target/nrf52.cfg"
        -c "program \"${SoftDevice_FIRMWARE}\" exit"
    )
    add_custom_target(${TARGET} COMMAND ${SoftDevice_OPENOCD} ${OPENOCD_ARGS} DEPENDS ${SOFTDEVICE_FIRMWARE})
endfunction()

function(SoftDevice_generate_linker_script TARGET)
    cmake_parse_arguments(SoftDevice "" "SOFTDEVICE;RAM" "" ${ARGN})
    if(NOT SoftDevice_SOFTDEVICE)
        message(FATAL_ERROR "SOFTDEVICE must be specified  (S140, S132, etc)")
    endif()
    if(NOT SoftDevice_RAM)
        message(FATAL_ERROR "RAM must be specified")
    endif()

    nrf52_get_chip(${TARGET} NRF52_CHIP NRF52_CHIP_VARIANT)
    nrf52_linker_sizes_from_device(${NRF52_CHIP} ${NRF52_CHIP_VARIANT} CHIP_RAM CHIP_FLASH)

    math(EXPR FLASH_START "0x00000000 + ${SoftDevice_${SoftDevice_SOFTDEVICE}_SIZE}")
    math(EXPR RAM_START "0x20000000 + ${SoftDevice_RAM}")
    math(EXPR FLASH_SIZE "${CHIP_FLASH} - ${SoftDevice_${SoftDevice_SOFTDEVICE}_SIZE}")
    math(EXPR RAM_SIZE "${CHIP_RAM} - ${SoftDevice_RAM}")

    if(${CMAKE_VERSION} VERSION_GREATER "3.13.0")
        math(EXPR FLASH_START "${FLASH_START}" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR RAM_START "${RAM_START}" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR FLASH_SIZE "${FLASH_SIZE}" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR RAM_SIZE "${RAM_SIZE}" OUTPUT_FORMAT HEXADECIMAL)
    endif()

    set(NRF52_LINKER_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.ld)
    nrf52_linker_generate_script(${TARGET} "${NRF52_LINKER_FILE}" FLASH_START ${FLASH_START} FLASH_SIZE ${FLASH_SIZE} RAM_START ${RAM_START} RAM_SIZE ${RAM_SIZE})
    set(SoftDevice_LINKER_SCRIPT_SRC
        "MEMORY\n"
        "{\n"
        "    SOFTDEVICE (rx) : ORIGIN = 0x00000, LENGTH = ${SoftDevice_${SoftDevice_SOFTDEVICE}_SIZE}\n"
        "}\n"
        "SECTIONS\n"
        "{\n"
        "   .softdevice :\n"
        "   {\n"
        "       KEEP(*(.sd.*))\n"
        "   } > SOFTDEVICE\n"
        "}\n"
    )
    file(APPEND "${NRF52_LINKER_FILE}" ${SoftDevice_LINKER_SCRIPT_SRC})
    nrf52_add_linker_script(${TARGET} "${NRF52_LINKER_FILE}")
endfunction()

foreach(COMP ${SoftDevice_FIND_COMPONENTS})
    string(TOLOWER ${COMP} COMP_LOWER)
    
    find_path(SoftDevice_${COMP}_INCLUDE_DIR
        NAMES ble.h
        PATHS "${NRF5_SDK_PATH}/components/softdevice/${COMP_LOWER}/headers"
    )
    find_file(SoftDevice_${COMP}_CONFIG_HEADER
        NAMES nrf_sdm.h
        PATHS "${NRF5_SDK_PATH}/components/softdevice/${COMP_LOWER}/headers"
    )
    find_file(SoftDevice_${COMP}_MBR_HEADER
        NAMES nrf_mbr.h
        PATHS "${NRF5_SDK_PATH}/components/softdevice/${COMP_LOWER}/headers/nrf52"
    )

    nrf52_sd_parse_headers(${COMP})
    # FIXME: SoftDevice version = version of last component found
    set(SoftDevice_VERSION ${SoftDevice_${COMP}_VERSION})

    find_file(SoftDevice_${COMP}_FIRMWARE
        NAMES ${COMP_LOWER}_nrf52_${SoftDevice_${COMP}_VERSION}_softdevice.hex
        PATHS "${NRF5_SDK_PATH}/components/softdevice/${COMP_LOWER}/hex"
    )

    if((SoftDevice_${COMP}_INCLUDE_DIR) AND (SoftDevice_${COMP}_CONFIG_HEADER) AND
            (SoftDevice_${COMP}_MBR_HEADER))
        set(SoftDevice_${COMP}_FOUND TRUE)
        list(APPEND SoftDevice_INCLUDE_DIRS ${SoftDevice_${COMP}_INCLUDE_DIR})
    else()
        set(SoftDevice_${COMP}_FOUND FALSE)
    endif()

    if(NOT SoftDevice_${COMP}_FIRMWARE)
        message(WARNING "Cannot find SoftDevice firmware file")
    else()
        add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${COMP}.o"
            COMMAND arm-none-eabi-objcopy ARGS "${SoftDevice_${COMP}_FIRMWARE}" --prefix-sections .sd --gap-fill 0xFF -B armv7e-m -O elf32-littlearm "${CMAKE_CURRENT_BINARY_DIR}/${COMP}.o"
            MAIN_DEPENDENCY "${SoftDevice_${COMP}_FIRMWARE}"
        )
    endif()

    if(SoftDevice_${COMP}_FOUND AND NOT TARGET SoftDevice::${COMP})
        add_library(SoftDevice::${COMP} INTERFACE IMPORTED)
        target_include_directories(SoftDevice::${COMP} INTERFACE "${SoftDevice_${COMP}_INCLUDE_DIR}")
        target_compile_definitions(SoftDevice::${COMP} INTERFACE -D${COMP})
        add_library(SoftDevice::${COMP}Firmware INTERFACE IMPORTED)
        target_sources(SoftDevice::${COMP}Firmware INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${COMP}.o")
    endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SoftDevice
    REQUIRED_VARS SoftDevice_INCLUDE_DIRS
    FOUND_VAR SoftDevice_FOUND
    VERSION_VAR SoftDevice_VERSION
    HANDLE_COMPONENTS
)
