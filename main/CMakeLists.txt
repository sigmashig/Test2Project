# Get build configuration from parent CMakeLists.txt
get_property(BUILD_CONFIG CACHE BUILD_CONFIG PROPERTY VALUE)

idf_component_register(SRCS "hello_world_main.c"
                       PRIV_REQUIRES spi_flash
                       INCLUDE_DIRS "")

# Set compile definitions based on configuration
# These will be available in C code via #if directives
if(BUILD_CONFIG STREQUAL "dev")
    target_compile_definitions(${COMPONENT_LIB} PRIVATE BUILD_CONFIG_DEV=1)
elseif(BUILD_CONFIG STREQUAL "test")
    target_compile_definitions(${COMPONENT_LIB} PRIVATE BUILD_CONFIG_TEST=1)
elseif(BUILD_CONFIG STREQUAL "production")
    target_compile_definitions(${COMPONENT_LIB} PRIVATE BUILD_CONFIG_PRODUCTION=1)
else()
    target_compile_definitions(${COMPONENT_LIB} PRIVATE BUILD_CONFIG_DEFAULT=1)
endif()
