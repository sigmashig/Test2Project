# The following lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.16)

# ============================================================================
# Build Configuration Settings
# ============================================================================
# Read build configuration from VS Code settings.json (fallback if not set via command line)
set(VSCODE_SETTINGS_FILE "${CMAKE_SOURCE_DIR}/.vscode/settings.json")
set(BUILD_CONFIG_DEFAULT "dev")

# Tell CMake to reconfigure when settings.json or marker file changes
set(BUILD_CONFIG_MARKER_FILE "${CMAKE_SOURCE_DIR}/build_config_marker.txt")
if(EXISTS ${VSCODE_SETTINGS_FILE})
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY CMAKE_CONFIGURE_DEPENDS ${VSCODE_SETTINGS_FILE})
endif()
if(EXISTS ${BUILD_CONFIG_MARKER_FILE})
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY CMAKE_CONFIGURE_DEPENDS ${BUILD_CONFIG_MARKER_FILE})
endif()

# Read current value from settings.json to compare with cache
set(BUILD_CONFIG_FROM_SETTINGS "")
##message(STATUS "1.BUILD_CONFIG_FROM_SETTINGS: ${BUILD_CONFIG_FROM_SETTINGS}")
if(EXISTS ${VSCODE_SETTINGS_FILE})
  ##  message(STATUS "1.1.Reading settings.json file: ${VSCODE_SETTINGS_FILE}")
    file(READ ${VSCODE_SETTINGS_FILE} SETTINGS_JSON)
    string(REGEX MATCH "\"buildConfig\"[ ]*:[ ]*\"([^\"]+)\"" BUILD_CONFIG_MATCH "${SETTINGS_JSON}")
  ##  message(STATUS "2.BUILD_CONFIG_MATCH: ${BUILD_CONFIG_MATCH}")
    if(BUILD_CONFIG_MATCH)
        string(REGEX REPLACE "\"buildConfig\"[ ]*:[ ]*\"([^\"]+)\"" "\\1" BUILD_CONFIG_FROM_SETTINGS "${BUILD_CONFIG_MATCH}")
    ##    message(STATUS "3.BUILD_CONFIG_FROM_SETTINGS: ${BUILD_CONFIG_FROM_SETTINGS}")
    endif()
    ##message(STATUS "4.BUILD_CONFIG_FROM_SETTINGS: ${BUILD_CONFIG_FROM_SETTINGS}")
else()
    ##message(STATUS "5.BUILD_CONFIG_FROM_SETTINGS not found")
endif()

# Determine the target BUILD_CONFIG value
# Priority: 1) settings.json, 2) command line (-D), 3) default
# Note: We check if BUILD_CONFIG was passed on command line by checking if it's in CMAKE_ARGS
# But a simpler approach: always prefer settings.json if it exists, then command line, then default

if(BUILD_CONFIG_FROM_SETTINGS)
    # settings.json takes highest priority
    string(STRIP "${BUILD_CONFIG_FROM_SETTINGS}" BUILD_CONFIG_TARGET)
    ##message(STATUS "Build config from VS Code settings: '${BUILD_CONFIG_TARGET}'")
elseif(DEFINED BUILD_CONFIG)
    # Command line takes second priority - trim whitespace
    string(STRIP "${BUILD_CONFIG}" BUILD_CONFIG_TARGET)
    ##message(STATUS "Build config from command line: '${BUILD_CONFIG_TARGET}'")
else()
    # Default fallback
    set(BUILD_CONFIG_TARGET "${BUILD_CONFIG_DEFAULT}")
    ##message(STATUS "Build config not found, using default: '${BUILD_CONFIG_TARGET}'")
endif()

# Set BUILD_CONFIG in cache - always use the target value (FORCE to override any cached value)
set(BUILD_CONFIG "${BUILD_CONFIG_TARGET}" CACHE STRING "Build configuration" FORCE)
message(STATUS "BUILD CONFIGURATION: '${BUILD_CONFIG}'")

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
# "Trim" the build. Include the minimal set of components, main, and anything it depends on.
idf_build_set_property(MINIMAL_BUILD ON)
project(Test2Project)

# Set COM port as environment variable for idf.py

# Display configuration information - trim and compare
string(STRIP "${BUILD_CONFIG}" BUILD_CONFIG_CLEAN)
if(BUILD_CONFIG_CLEAN STREQUAL "dev")
    message(STATUS "Building with DEV configuration")
    set(FLASH_PORT "COM5" CACHE STRING "COM port for flashing" FORCE)
elseif(BUILD_CONFIG_CLEAN STREQUAL "test")
    message(STATUS "Building with TEST configuration")
    set(FLASH_PORT "COM5" CACHE STRING "COM port for flashing" FORCE)
elseif(BUILD_CONFIG_CLEAN STREQUAL "production")
    message(STATUS "Building with PRODUCTION configuration")
    set(FLASH_PORT "COM3" CACHE STRING "COM port for flashing" FORCE)
else()
    message(WARNING "Unknown BUILD_CONFIG value: '${BUILD_CONFIG_CLEAN}' - using DEFAULT configuration")
    message(STATUS "Building with DEFAULT configuration")
    set(FLASH_PORT "COM5" CACHE STRING "COM port for flashing" FORCE)
endif()
set(ENV{ESPTOOL_PORT} ${FLASH_PORT})
message(STATUS "COM Port: ${FLASH_PORT}")

# Update VS Code settings.json with the correct port
set(VSCODE_SETTINGS_FILE "${CMAKE_SOURCE_DIR}/.vscode/settings.json")
if(EXISTS ${VSCODE_SETTINGS_FILE})
    file(READ ${VSCODE_SETTINGS_FILE} SETTINGS_JSON)
    string(REGEX REPLACE "\"idf\\.portWin\"[ ]*:[ ]*\"[^\"]*\"" "\"idf.portWin\": \"${FLASH_PORT}\"" SETTINGS_JSON "${SETTINGS_JSON}")
    file(WRITE ${VSCODE_SETTINGS_FILE} "${SETTINGS_JSON}")
    message(STATUS "Updated VS Code settings.json: idf.portWin = ${FLASH_PORT}")
endif()

# Remove build_config_marker.txt after successful build
# This file is created by "Set Build Config" tasks to trigger reconfiguration
if(EXISTS ${BUILD_CONFIG_MARKER_FILE})
    # Add POST_BUILD command to remove marker file after successful build
    # The target name is the project name
    add_custom_command(
        TARGET ${CMAKE_PROJECT_NAME}.elf
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E remove ${BUILD_CONFIG_MARKER_FILE}
        COMMENT "Removing build_config_marker.txt after successful build"
        VERBATIM
    )
    message(STATUS "Will remove build_config_marker.txt after successful build")
endif()
