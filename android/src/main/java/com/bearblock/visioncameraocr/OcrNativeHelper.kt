package com.bearblock.visioncameraocr

import android.hardware.HardwareBuffer

object OcrNativeHelper {
  init {
    System.loadLibrary("VisionCameraOcr")
  }

  external fun pointerToHardwareBuffer(pointer: Long): HardwareBuffer?
}
