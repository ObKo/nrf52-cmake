if(NOT ChibiOS_DIR)
    return()
endif()

if (NOT ("Core" IN_LIST ChibiOS_FIND_COMPONENTS))
    return()
endif()

find_path(ChibiOS_RT_INCLUDE_DIR
    NAMES ch.h
    PATHS ${ChibiOS_DIR}/os/rt/include
)
if(ChibiOS_RT_INCLUDE_DIR)
    set(ChibiOS_Core_FOUND TRUE)
endif()

add_library(ChibiOS::OSLib INTERFACE IMPORTED)
target_sources(ChibiOS::OSLib INTERFACE 
    ${ChibiOS_DIR}/os/oslib/src/chmboxes.c
    ${ChibiOS_DIR}/os/oslib/src/chmemcore.c
    ${ChibiOS_DIR}/os/oslib/src/chmemheaps.c
    ${ChibiOS_DIR}/os/oslib/src/chmempools.c
    ${ChibiOS_DIR}/os/oslib/src/chpipes.c
    ${ChibiOS_DIR}/os/oslib/src/chfactory.c
)
target_include_directories(ChibiOS::OSLib INTERFACE 
    ${ChibiOS_DIR}/os/oslib/include
)

add_library(ChibiOS::RT INTERFACE IMPORTED)
target_sources(ChibiOS::RT INTERFACE 
    ${ChibiOS_DIR}/os/rt/src/chsys.c
    ${ChibiOS_DIR}/os/rt/src/chdebug.c
    ${ChibiOS_DIR}/os/rt/src/chtrace.c
    ${ChibiOS_DIR}/os/rt/src/chvt.c
    ${ChibiOS_DIR}/os/rt/src/chschd.c
    ${ChibiOS_DIR}/os/rt/src/chthreads.c
    ${ChibiOS_DIR}/os/rt/src/chtm.c
    ${ChibiOS_DIR}/os/rt/src/chstats.c
    ${ChibiOS_DIR}/os/rt/src/chregistry.c
    ${ChibiOS_DIR}/os/rt/src/chsem.c
    ${ChibiOS_DIR}/os/rt/src/chmtx.c
    ${ChibiOS_DIR}/os/rt/src/chcond.c
    ${ChibiOS_DIR}/os/rt/src/chevents.c
    ${ChibiOS_DIR}/os/rt/src/chmsg.c
    ${ChibiOS_DIR}/os/rt/src/chdynamic.c
    ${ChibiOS_DIR}/os/hal/osal/rt/osal.c
)
target_include_directories(ChibiOS::RT INTERFACE 
    ${ChibiOS_DIR}/os/license
    ${ChibiOS_DIR}/os/rt/include
    ${ChibiOS_DIR}/os/hal/osal/rt
)
target_link_libraries(ChibiOS::RT INTERFACE ChibiOS::OSLib)

add_library(ChibiOS::NIL INTERFACE IMPORTED)
target_sources(ChibiOS::NIL INTERFACE 
    ${ChibiOS_DIR}/os/nil/src/ch.c
    ${ChibiOS_DIR}/os/hal/osal/nil/osal.c
)
target_include_directories(ChibiOS::NIL INTERFACE
    ${ChibiOS_DIR}/os/license
    ${ChibiOS_DIR}/os/nil/include
    ${ChibiOS_DIR}/os/hal/osal/nil
)
target_link_libraries(ChibiOS::NIL INTERFACE ChibiOS::OSLib)

add_library(ChibiOS::ARMCortexM4 INTERFACE IMPORTED)
target_sources(ChibiOS::ARMCortexM4 INTERFACE 
    ${ChibiOS_DIR}/os/common/startup/ARMCMx/compilers/GCC/crt1.c
    ${ChibiOS_DIR}/os/common/ports/ARMCMx/chcore.c
    ${ChibiOS_DIR}/os/common/ports/ARMCMx/chcore_v7m.c
    ${ChibiOS_DIR}/os/common/ports/ARMCMx/compilers/GCC/chcoreasm_v7m.S
    ${ChibiOS_DIR}/os/common/startup/ARMCMx/compilers/GCC/crt0_v7m.S
    ${ChibiOS_DIR}/os/common/startup/ARMCMx/compilers/GCC/vectors.S
)
target_include_directories(ChibiOS::ARMCortexM4 INTERFACE 
    ${ChibiOS_DIR}/os/common/ports/ARMCMx
    ${ChibiOS_DIR}/os/common/ports/ARMCMx/compilers/GCC
    ${ChibiOS_DIR}/os/common/startup/ARMCMx/compilers/GCC/ld
    ${ChibiOS_DIR}/os/common/ext/ARM/CMSIS/Core/Include
)
target_link_options(ChibiOS::ARMCortexM4 INTERFACE -L "${ChibiOS_DIR}/os/common/startup/ARMCMx/compilers/GCC/ld")

