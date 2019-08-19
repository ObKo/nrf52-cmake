## Minimal example
CMakeLists.txt:
```cmake
# Can be setted in cli
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../nrf52.cmake)

cmake_minimum_required(VERSION 3.8)

project(example C ASM)

add_executable(example main.c)
set_target_properties(example PROPERTIES NRF52_CHIP NRF52832-QFAB)
nrf52_target(example)
```
main.c:
```cpp
int main()
{
    for(;;);
    return 0;
}
```
configure:
```
$ cmake ./
-- No TOOLCHAIN_PATH specified, using default: /usr
-- No TOOLCHAIN_TRIPLET specified, using default: arm-none-eabi
-- No NRF5_SDK_PATH specified, using default: /opt/nRF5_SDK
-- The C compiler identification is GNU 9.2.0
-- The ASM compiler identification is GNU
-- Found assembler: /bin/arm-none-eabi-gcc
-- Check for working C compiler: /bin/arm-none-eabi-gcc
-- Check for working C compiler: /bin/arm-none-eabi-gcc -- works
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Detecting C compile features
-- Detecting C compile features - done
-- Configuring done
-- Generating done
-- Build files have been written to: 
```
build:
```
$ cmake --build ./
Scanning dependencies of target example
[ 25%] Building C object CMakeFiles/example.dir/main.c.obj
[ 50%] Building ASM object CMakeFiles/example.dir/opt/nRF5_SDK/modules/nrfx/mdk/gcc_startup_nrf52.S.obj
[ 75%] Building C object CMakeFiles/example.dir/opt/nRF5_SDK/modules/nrfx/mdk/system_nrf52.c.obj
[100%] Linking C executable example
[100%] Built target example
```

## nrf52-cmake features reference 

The main piece of nrf52-cmake is toolchain file **nrf52.cmake**.
It setups cross-compiling enviroment and defines some useful functions.
This file should be passed to cmake using `CMAKE_TOOLCHAIN_FILE` variable,
either using command line or in **CMakeLists.txt**.
This toolchain file uses following variables:

* `TOOLCHAIN_PATH` (default: `/usr`) - path to ARM GCC toolchain, 
compiler should be located in `${TOOLCHAIN_PATH}/bin`

* `TOOLCHAIN_TRIPLET` (default: `arm-none-eabi`) - compiler target triplet, 
cmake will search for `${TOOLCHAIN_TRIPLET}-gcc` executable

* `NRF5_SDK_PATH` (default: `/opt/nRF5_SDK`) - **optional** path to NRF5 SDK.
Required if you're going to use startup code and linker script from SDK 
(most common scenario)

### Functions

Besides toolchain setup nrf52-cmake defines some useful functions, which 
works on cmake targets and target properties. Some properties can 
(or should) be setted on target to use nrf52-cmake functions:

* `NRF52_CHIP` - **mandatory** property to specify NRF52 device. 
Can be either NRF52xxx or NRF52xxx-xxxx form. Currently only 
`NRF52840`, `NRF52832`, `NRF52811`, `NRF52810` are supported.

* `NO_SDK` - **optional** tells nrf52-cmake not to use any source code from 
NRF5 SDK. You'll have to provide all sources and linker script by yourself.

* `CUSTOM_LINKER_SCRIPT` - **optional** tells nrf52-cmake not to use 
comon linker script from NRF5 SDK.

* `SOFTDEVICE` - **optional** property telling that target will be running 
together with SoftDevice firmware (so correct linker script will be used).

nrf52-cmake adds following useful functions:

* `nrf52_get_chip(<target> <chip> <internal> <variant>)` - parses `NRF52_CHIP`
property on `<target>` and outputs some useful information:
    - `<chip>` - specific chip code (840, 832, etc.)
    - `<internal>` - Nordic code for device (S140, S132, etc.)
    - `<variant>` - chip variant (AA, AB, etc), default will be AA.

* `nrf52_add_sdk_startup(<target>)` - search and adds startup sources to target 
from nRF5 SDK.

* `nrf52_add_sdk_linker_script(<target>)` - search and adds linker script to 
target from nRF5 SDK.

* `nrf52_add_linker_script(<target> <script>)` - add (custom) linker script to 
target.

* `nrf52_configure_compiler(<target>)` - configure all compiler options

* `nrf52_target(<target>)` - process target and and make everything listed 
above.


