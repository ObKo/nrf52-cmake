if(NOT ChibiOS_FIND_COMPONENTS)
    set(ChibiOS_FIND_COMPONENTS Core;HAL)
endif()

find_path(ChibiOS_DIR
    NAMES os/license/chversion.h
    PATHS ${ChibiOS_ROOT} /usr/src/ChibiOS
)

find_path(ChibiOS_Contrib_DIR
    NAMES os/hal/include/hal_community.h
    PATHS ${ChibiOS_Contrib_ROOT} /usr/src/ChibiOS-Contrib
)

if(ChibiOS_DIR)
    file(STRINGS "${ChibiOS_DIR}/os/license/chversion.h" VERSION_STRING REGEX "CH_VERSION +\".+\"")
    string(REGEX MATCH "CH_VERSION +\"([0-9]+).([0-9]+).([0-9]+)\"" MATCHED ${VERSION_STRING})
    set(ChibiOS_VERSION_MAJOR ${CMAKE_MATCH_1})
    set(ChibiOS_VERSION_MINOR ${CMAKE_MATCH_2})
    set(ChibiOS_VERSION_PATCH ${CMAKE_MATCH_3})
    set(ChibiOS_VERSION "${ChibiOS_VERSION_MAJOR}.${ChibiOS_VERSION_MINOR}.${ChibiOS_VERSION_PATCH}")
endif()

function(ChibiOS_set_stack_sizes TARGET)
    cmake_parse_arguments(STACK "DEFAULT" "MAIN;PROCESS" "" ${ARGN})
    if(STACK_DEFAULT OR (NOT STACK_MAIN))
        set(STACK_MAIN "0x400")
    endif()
    if(STACK_DEFAULT OR (NOT STACK_PROCESS))
        set(STACK_PROCESS "0x400")
    endif()
    target_link_options(${TARGET} PRIVATE "-Wl,--defsym=__main_stack_size__=${STACK_MAIN}")
    target_link_options(${TARGET} PRIVATE "-Wl,--defsym=__process_stack_size__=${STACK_PROCESS}")
endfunction()
    
include(ChibiOS/Core)
include(ChibiOS/HAL)
include(ChibiOS/NRF5)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ChibiOS
    REQUIRED_VARS ChibiOS_DIR
    VERSION_VAR ChibiOS_VERSION
    HANDLE_COMPONENTS
)
