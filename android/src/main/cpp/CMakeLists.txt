cmake_minimum_required(VERSION 3.10)
project(VisionCameraOcr)

add_library(VisionCameraOcr SHARED
  OcrNativeHelper.cpp
)

# Include Nitrogen generated files
include(${CMAKE_SOURCE_DIR}/../nitrogen/generated/android/VisionCameraOcr+autolinking.cmake)

find_library(android-lib android)

target_link_libraries(VisionCameraOcr ${android-lib})
