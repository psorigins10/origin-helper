cmake_minimum_required(VERSION 3.20)
project(ORIGINHelper VERSION 0.1.0 DESCRIPTION "Linux laptop hardware management utility" LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
include(CTest)
include(GNUInstallDirs)

add_library(origin-core
    src/core/system_info.cpp
    src/hardware/hardware_detector.cpp
    src/platform/linux_backend.cpp
    src/power/power_profile.cpp
)
target_include_directories(origin-core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_compile_options(origin-core PRIVATE -Wall -Wextra -Wpedantic)

add_executable(origin-helper src/main.cpp)
target_link_libraries(origin-helper PRIVATE origin-core)
target_compile_options(origin-helper PRIVATE -Wall -Wextra -Wpedantic)

if(BUILD_TESTING)
    add_executable(origin-helper-tests tests/test_main.cpp)
    target_link_libraries(origin-helper-tests PRIVATE origin-core)
    target_compile_options(origin-helper-tests PRIVATE -Wall -Wextra -Wpedantic)
    add_test(NAME origin-helper-tests COMMAND origin-helper-tests)
endif()

install(TARGETS origin-core origin-helper EXPORT ORIGINHelperTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
