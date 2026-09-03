cmake_minimum_required(VERSION 3.16)

project(embedded-linux-ui VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED APP_VERSION)
    set(APP_VERSION ${PROJECT_VERSION})
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Gui Network Qml Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(embedded-linux-ui
    src/main.cpp
    src/SystemInfo.cpp
    src/UpdateController.cpp
)

qt_add_qml_module(embedded-linux-ui
    URI EmbeddedLinuxDemo
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/UpdateScreen.qml
)

target_compile_definitions(embedded-linux-ui PRIVATE APP_VERSION="${APP_VERSION}")

target_link_libraries(embedded-linux-ui PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
)

install(TARGETS embedded-linux-ui RUNTIME DESTINATION bin)
