cmake_minimum_required(VERSION 3.10)
project(VisionCameraOcr)

add_library(VisionCameraOcr SHARED
  src/main/cpp/OcrNativeHelper.cpp
)

# Include Nitrogen generated files
include(${CMAKE_SOURCE_DIR}/../nitrogen/generated/android/VisionCameraOcr+autolinking.cmake)

find_library(android-lib android)

# Android 15+ requires 16KB page size alignment for loaded .so files
target_link_options(VisionCameraOcr PRIVATE "-Wl,-z,max-page-size=16384" "-Wl,-z,common-page-size=16384")

target_link_libraries(VisionCameraOcr ${android-lib})
