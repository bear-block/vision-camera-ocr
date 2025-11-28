package com.bearblock.visioncameraocr.visioncameraocr

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class OcrFrameProcessorPluginPackage : ReactPackage {
  init {
    // Access the companion object property to ensure initialization
    // This triggers the companion object's init block, registering the plugin.
    // The registration is idempotent, so it's safe to access multiple times.
    OcrFrameProcessorPluginRegistry.initialized
  }

  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return emptyList()
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}