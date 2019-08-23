if(NOT SoftDevice_FIND_COMPONENTS)
    set(SoftDevice_FIND_COMPONENTS S112;S132;S140;S212;S312;S332;S340)
endif()

set(SoftDevice_INCLUDE_DIRS)

foreach(COMP ${SoftDevice_FIND_COMPONENTS})
    string(TOLOWER ${COMP} COMP_LOWER)
    
    find_path(SoftDevice_${COMP}_INCLUDE_DIR
        NAMES ble.h
        PATHS "${NRF5_SDK_PATH}/components/softdevice/${COMP_LOWER}/headers"
    )
    
    set(TMP_INCLUDE_DIR "${SoftDevice_${COMP}_INCLUDE_DIR}")
    if(TMP_INCLUDE_DIR)
        set(SoftDevice_${COMP}_FOUND TRUE)
        list(APPEND SoftDevice_INCLUDE_DIRS ${TMP_INCLUDE_DIR})
    else()
        set(SoftDevice_${COMP}_FOUND FALSE)
    endif()

    if(SoftDevice_${COMP}_FOUND AND NOT TARGET SoftDevice::${COMP})
        add_library(SoftDevice::${COMP} INTERFACE IMPORTED)
        target_include_directories(SoftDevice::${COMP} INTERFACE "${TMP_INCLUDE_DIR}")
        target_compile_definitions(SoftDevice::${COMP} INTERFACE -D${COMP})
    endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SoftDevice 
    REQUIRED_VARS SoftDevice_INCLUDE_DIRS
    FOUND_VAR SoftDevice_FOUND
    HANDLE_COMPONENTS
)
