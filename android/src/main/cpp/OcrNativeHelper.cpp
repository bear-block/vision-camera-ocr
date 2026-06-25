#include <jni.h>
#include <android/hardware_buffer.h>
#include <android/hardware_buffer_jni.h>

extern "C" {

JNIEXPORT jobject JNICALL
Java_com_bearblock_visioncameraocr_OcrNativeHelper_pointerToHardwareBuffer(
    JNIEnv* env, jclass, jlong pointer) {
#if __ANDROID_API__ >= 26
  auto* hardwareBuffer = reinterpret_cast<AHardwareBuffer*>(pointer);
  return AHardwareBuffer_toHardwareBuffer(env, hardwareBuffer);
#else
  return nullptr;
#endif
}

}
