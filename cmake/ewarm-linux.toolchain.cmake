### BEGIN CMAKE_TOOLCHAIN_FILE
# "Generic" is used when compiling for bare-metal
set(CMAKE_SYSTEM_NAME Generic)

# Set the EW installation root directory
#(Avoid spaces in the path or you need to escape them)
set(EW_ROOT_DIR "/opt/iarsystems/bxarm/arm/")

# Compiler flags needed to compile for this CPU
set(CPU_FLAGS "--cpu Cortex-M4F")

# Set up the CMake variables for compiler and assembler
# (The reason for both C and CXX variables is that CMake
# treats C and C++ tools individually)
set(CMAKE_C_COMPILER "${EW_ROOT_DIR}/bin/iccarm" "${CPU_FLAGS} --dlib_config normal")
set(CMAKE_CXX_COMPILER "${EW_ROOT_DIR}/bin/iccarm" "${CPU_FLAGS} --dlib_config normal")
set(CMAKE_ASM_COMPILER "${EW_ROOT_DIR}/bin/iasmarm" "${CPU_FLAGS}")

# Build with cmake -S. -Bbuild -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=cmake/ewarm-linux.toolchain.cmake

### END CMAKE_TOOLCHAIN_FILE
