# 2.6.3 is needed for ctest support
# 3.1 is needed for target_sources
# 3.8 is needed for try_compile improvements (CMP0067)
cmake_minimum_required(VERSION 3.8)

project(CppUTest
  VERSION 4.0
)

if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.21")
  # PROJECT_IS_TOP_LEVEL is defined automatically
elseif (CMAKE_CURRENT_BINARY_DIR STREQUAL CMAKE_BINARY_DIR)
  set(PROJECT_IS_TOP_LEVEL TRUE)
else()
  set(PROJECT_IS_TOP_LEVEL FALSE)
endif()

###############
# Conan support
###############
if (EXISTS "${CMAKE_BINARY_DIR}/conanbuildinfo.cmake")
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    message(STATUS "conan_basic_setup()")
    conan_basic_setup()
endif()

include(CTest)

include(CMakeDependentOption)
option(CPPUTEST_STD_C_LIB_DISABLED "Disable the standard C library")

include(CheckCXXSourceCompiles)
check_cxx_source_compiles(
  "int main(int argc, char ** argv) { throw 20; }"
  CPPUTEST_HAVE_EXCEPTIONS
)

if((CMAKE_CXX_COMPILER_ID STREQUAL "Clang") AND (CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC"))
  set(is_clang_cl TRUE)
endif()

cmake_dependent_option(CPPUTEST_STD_CPP_LIB_DISABLED "Use the standard C++ library"
  OFF "NOT CPPUTEST_STD_C_LIB_DISABLED;CPPUTEST_HAVE_EXCEPTIONS" ON)
option(CPPUTEST_FLAGS "Use the CFLAGS/CXXFLAGS/LDFLAGS set by CppUTest" ${PROJECT_IS_TOP_LEVEL})
cmake_dependent_option(CPPUTEST_MEM_LEAK_DETECTION_DISABLED "Enable memory leak detection"
  OFF "CPPUTEST_FLAGS;NOT BORLAND;NOT CPPUTEST_STD_C_LIB_DISABLED;NOT is_clang_cl" ON)
option(CPPUTEST_EXTENSIONS "Use the CppUTest extension library" ON)

include(CheckTypeSize)
check_type_size("long long" SIZEOF_LONGLONG)
cmake_dependent_option(CPPUTEST_USE_LONG_LONG "Support long long"
  YES "HAVE_SIZEOF_LONGLONG" OFF)

cmake_dependent_option(CPPUTEST_BUILD_TESTING "Compile and make tests for CppUTest"
  ${PROJECT_IS_TOP_LEVEL} "BUILD_TESTING" OFF)
cmake_dependent_option(CPPUTEST_TEST_DISCOVERY "Build time test discover"
  ON "CPPUTEST_BUILD_TESTING;CMAKE_CROSSCOMPILING_EMULATOR OR NOT CMAKE_CROSSCOMPILING" OFF)
cmake_dependent_option(CPPUTEST_EXAMPLES "Compile and make examples?"
  ${PROJECT_IS_TOP_LEVEL} "NOT CPPUTEST_STD_CPP_LIB_DISABLED" OFF)
cmake_dependent_option(CPPUTEST_LIBNAME_POSTFIX_BITSIZE "Add architecture bitsize (32/64) to the library name?"
  OFF "PROJECT_IS_TOP_LEVEL" OFF)

if(DEFINED CPP_PLATFORM)
  message(DEPRECATION
    "The CPP_PLATFORM variable has been deprecated. "
    "Use CPPUTEST_PLATFORM instead."
  )
else()
  if(MSVC)
    set(CPP_PLATFORM VisualCpp)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "IAR")
    set(CPP_PLATFORM Iar)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "ARMCC")
    set(CPP_PLATFORM armcc)
  elseif(DOS)
    set(CPP_PLATFORM Dos)
  elseif(BORLAND)
    set(CPP_PLATFORM Borland)
  elseif(CPPUTEST_STD_C_LIB_DISABLED)
    set(CPP_PLATFORM GccNoStdC)
  else()
    set(CPP_PLATFORM Gcc)
  endif()
endif()
set(CPPUTEST_PLATFORM "${CPP_PLATFORM}" CACHE STRING "Platform implementation")
set_property(
  CACHE CPPUTEST_PLATFORM
  PROPERTY STRINGS
    armcc
    Borland
    C2000
    Dos
    Gcc
    GccNoStdC
    Iar
    Keil
    Symbian
    VisualCpp
    OFF
)

include(CheckCXXSymbolExists)
check_cxx_symbol_exists(fopen_s "stdio.h" CPPUTEST_HAVE_SECURE_STDLIB)
cmake_dependent_option(CPPUTEST_USE_SECURE_STDLIB "Use MSVC safe functions"
  ON "WIN32;CPPUTEST_HAVE_SECURE_STDLIB" OFF)

set( CppUTestLibName "CppUTest" )
set( CppUTestExtLibName "CppUTestExt" )

if(CPPUTEST_LIBNAME_POSTFIX_BITSIZE)
  if( "${CMAKE_SIZEOF_VOID_P}" STREQUAL "8" )
      set( CppUTestLibName "${CppUTestLibName}64" )
      set( CppUTestExtLibName "${CppUTestExtLibName}64" )
  elseif( "${CMAKE_SIZEOF_VOID_P}" STREQUAL "4" )
      set( CppUTestLibName "${CppUTestLibName}32" )
      set( CppUTestExtLibName "${CppUTestExtLibName}32" )
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules")
if(NOT PROJECT_IS_TOP_LEVEL)
  set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
endif()

include(CppUTestConfigurationOptions)
if(PROJECT_IS_TOP_LEVEL)
  include(CppUTestWarningFlags)
endif()
include(CppUTestBuildTimeDiscoverTests)
include(CppUTestNormalizeTestOutputLocation)
include(GNUInstallDirs)

# Check for symbols before setting a lot of stuff
include(CheckTypeSize)
include(CheckStructHasMember)
set(CMAKE_REQUIRED_FLAGS ${CMAKE_CXX_FLAGS})
check_cxx_symbol_exists(FE_DIVBYZERO "fenv.h" CPPUTEST_HAVE_FENV)
check_cxx_symbol_exists(fork "unistd.h" CPPUTEST_HAVE_FORK)
check_cxx_symbol_exists(waitpid "sys/wait.h" CPPUTEST_HAVE_WAITPID)
check_cxx_symbol_exists(gettimeofday "sys/time.h" CPPUTEST_HAVE_GETTIMEOFDAY)
check_cxx_symbol_exists(pthread_mutex_lock "pthread.h" CPPUTEST_HAVE_PTHREAD_MUTEX_LOCK)

if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "IAR")
  check_cxx_symbol_exists(strdup "string.h" CPPUTEST_HAVE_STRDUP)
endif()
check_type_size("long long" SIZEOF_LONGLONG LANGUAGE CXX)
if(HAVE_SIZEOF_LONGLONG)
    set(CPPUTEST_HAVE_LONG_LONG_INT ON)
endif()

configure_file (
    "${PROJECT_SOURCE_DIR}/config.h.cmake"
    "${PROJECT_BINARY_DIR}/generated/CppUTestGeneratedConfig.h"
)

add_subdirectory(src)

target_include_directories(${CppUTestLibName}
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
)
target_compile_definitions(${CppUTestLibName}
  PUBLIC
    HAVE_CONFIG_H
)

if (CPPUTEST_BUILD_TESTING)
    add_subdirectory(tests)
endif ()

if (CPPUTEST_EXAMPLES)
  add_subdirectory(examples)
endif()

if(PROJECT_IS_TOP_LEVEL)
  include(cmake/install.cmake)
endif()
