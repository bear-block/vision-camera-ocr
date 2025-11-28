package com.bearblock.visioncameraocr.visioncameraocr

import com.mrousavy.camera.frameprocessors.FrameProcessorPluginRegistry

class OcrFrameProcessorPluginRegistry {
  companion object {
    /**
     * Companion object init block runs when the companion object is first accessed.
     * This ensures the plugin is registered early in the app lifecycle.
     */
    init {
      FrameProcessorPluginRegistry.addFrameProcessorPlugin("detectText") { proxy, options ->
        OcrFrameProcessorPlugin(proxy, options)
      }
    }

    /**
     * This property ensures the companion object is accessed when the Package is instantiated,
     * triggering the init block above. The registration is idempotent.
     */
    @JvmStatic
    val initialized: Unit = Unit
  }
}
