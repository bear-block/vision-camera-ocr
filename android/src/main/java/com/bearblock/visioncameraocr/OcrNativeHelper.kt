package com.bearblock.visioncameraocr

object OcrNativeHelper {
  init {
    System.loadLibrary("VisionCameraOcr")
  }

  external fun hardwareBufferToNv21(pointer: Long, width: Int, height: Int): ByteArray?
}
