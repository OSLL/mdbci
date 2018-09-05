cmake_minimum_required(VERSION 2.8)

add_executable(AppRun AppRun.c)

target_compile_definitions(AppRun
    PRIVATE -D_FILE_OFFSET_BITS=64
    PRIVATE -DENABLE_BINRELOC
)

install(
    TARGETS AppRun
    RUNTIME DESTINATION bin COMPONENT applications
    LIBRARY DESTINATION lib COMPONENT applications
    ARCHIVE DESTINATION lib/static COMPONENT applications
    INCLUDES DESTINATION include COMPONENT applications
)
