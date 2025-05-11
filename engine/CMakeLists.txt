cmake_minimum_required(VERSION 2.8.12)
set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(cotire)

# Enable C++17 support
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Enable colored output
set(CMAKE_COLOR_MAKEFILE ON)

# Compiler flags: No -Werror to avoid PCH warnings stopping build
add_compile_options(-Wall -pipe -fvisibility=hidden)

# Performance flags for release builds
set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -Ofast -march=native -mtune=native -DBOOST_DISABLE_ASSERTS -DNDEBUG -g")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-Ofast -march=native -mtune=native -DBOOST_DISABLE_ASSERTS -DNDEBUG -g")

# GCC-specific flags: Avoid -fno-strict-aliasing for PCH consistency
if(CMAKE_COMPILER_IS_GNUCXX)
    # add_compile_options(-fno-strict-aliasing) # Commented to prevent __STRICT_ANSI__ issues
endif()

# Include additional CMake modules
include(FindCXX11) # Should support C++17; verify compatibility
include(FindLTO)

# Find required packages
find_package(Crypto++ REQUIRED)
find_package(PugiXML REQUIRED)
find_package(MySQL REQUIRED)
find_package(Threads REQUIRED)

# Generate protocol files
set(protoc_cmd "${PROJECT_SOURCE_DIR}/proto/generate.sh")
execute_process(COMMAND ${protoc_cmd}
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/proto
                RESULT_VARIABLE protoc_result)
if(NOT protoc_result EQUAL 0)
    message(FATAL_ERROR "Protocol generation failed with exit code ${protoc_result}")
endif()

# Select LuaJIT if defined or auto-detected
if(DEFINED USE_LUAJIT AND NOT USE_LUAJIT)
    set(FORCE_LUAJIT ${USE_LUAJIT})
else()
    find_package(LuaJIT)
    set(FORCE_LUAJIT ${LuaJIT_FOUND})
endif()
option(USE_LUAJIT "Use LuaJIT" ${FORCE_LUAJIT})

if(FORCE_LUAJIT)
    if(APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000")
    endif()
else()
    find_package(Lua REQUIRED)
endif()

# Boost: Using 1.53.0; consider upgrading for better C++17/20 support
find_package(Boost 1.53.0 COMPONENTS system filesystem iostreams REQUIRED)

# Add source subdirectory
add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

# Include directories for dependencies
include_directories(${MYSQL_INCLUDE_DIR} ${LUA_INCLUDE_DIR} ${Boost_INCLUDE_DIRS} ${PUGIXML_INCLUDE_DIR} ${Crypto++_INCLUDE_DIR})

# Link libraries
target_link_libraries(tfs ${MYSQL_CLIENT_LIBS} ${LUA_LIBRARIES} ${Boost_LIBRARIES} ${Boost_FILESYSTEM_LIBRARY} ${PUGIXML_LIBRARIES} ${Crypto++_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})

# Unity Build configuration
option(ENABLE_UNITY_BUILD "Enable unity build" ON)
if(ENABLE_UNITY_BUILD)
    set_target_properties(tfs PROPERTIES COTIRE_ADD_UNITY_BUILD TRUE)
else()
    set_target_properties(tfs PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)
endif()

# Precompiled header: Enabled since it worked with C++17
set_target_properties(tfs PROPERTIES COTIRE_CXX_PREFIX_HEADER_INIT "src/otpch.h")
cotire(tfs)

# Debug compiler flags for diagnostics
message(STATUS "CXX Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "CXX Flags: ${CMAKE_CXX_FLAGS}")
message(STATUS "CXX Flags Performance: ${CMAKE_CXX_FLAGS_PERFORMANCE}")