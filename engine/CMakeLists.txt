cmake_minimum_required(VERSION 2.8.12)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(cotire)

# Configuração simples para colorir
set(CMAKE_COLOR_MAKEFILE ON)

add_compile_options(-Wall -Werror -pipe -fvisibility=hidden)

set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -Ofast -march=native -mtune=native -DBOOST_DISABLE_ASSERTS -DNDEBUG -g")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-Ofast -march=native -mtune=native -DBOOST_DISABLE_ASSERTS -DNDEBUG -g")

if (CMAKE_COMPILER_IS_GNUCXX)
    add_compile_options(-fno-strict-aliasing)
endif()

include(FindCXX11)
include(FindLTO)

# Find packages.
find_package(Crypto++ REQUIRED)
find_package(PugiXML REQUIRED)
find_package(MySQL REQUIRED)
find_package(Threads)

set (protoc_cmd "${PROJECT_SOURCE_DIR}/proto/generate.sh")
 
execute_process(COMMAND ${protoc_cmd}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/proto)

# Selects LuaJIT if user defines or auto-detected
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

find_package(Boost 1.53.0 COMPONENTS system filesystem iostreams REQUIRED)

add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

include_directories(${MYSQL_INCLUDE_DIR} ${LUA_INCLUDE_DIR} ${Boost_INCLUDE_DIRS} ${PUGIXML_INCLUDE_DIR} ${Crypto++_INCLUDE_DIR})
target_link_libraries(tfs ${MYSQL_CLIENT_LIBS} ${LUA_LIBRARIES} ${Boost_LIBRARIES} ${Boost_FILESYSTEM_LIBRARY} ${PUGIXML_LIBRARIES} ${Crypto++_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})

# Configuração para Unity Build
option(ENABLE_UNITY_BUILD "Enable unity build" ON)
if(ENABLE_UNITY_BUILD)
    set_target_properties(tfs PROPERTIES COTIRE_ADD_UNITY_BUILD TRUE)
else()
    set_target_properties(tfs PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)
endif()

set_target_properties(tfs PROPERTIES COTIRE_CXX_PREFIX_HEADER_INIT "src/otpch.h")
cotire(tfs)