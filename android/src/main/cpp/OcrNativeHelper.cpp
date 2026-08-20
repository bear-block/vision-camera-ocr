#include <jni.h>
#include <cstring>
#include <android/hardware_buffer.h>
#include "VisionCameraOcrOnLoad.hpp"

// Register Nitro HybridObjects on library load
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return margelo::nitro::visioncameraocr::initialize(vm);
}

extern "C" {

// Convert YUV HardwareBuffer to NV21 byte array for ML Kit.
// Bitmap.wrapHardwareBuffer produces a HARDWARE-config bitmap that ML Kit cannot process,
// so we lock the YUV planes directly and convert to NV21.
JNIEXPORT jbyteArray JNICALL
Java_com_bearblock_visioncameraocr_OcrNativeHelper_hardwareBufferToNv21(
    JNIEnv* env, jclass, jlong pointer, jint width, jint height) {
#if __ANDROID_API__ >= 29
  auto* buffer = reinterpret_cast<AHardwareBuffer*>(pointer);

  AHardwareBuffer_Planes planes;
  int result = AHardwareBuffer_lockPlanes(buffer,
      AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN, -1, nullptr, &planes);

  if (result != 0) return nullptr;

  int ySize = width * height;
  int nv21Size = ySize + (width * height / 2);

  jbyteArray nv21 = env->NewByteArray(nv21Size);
  if (nv21 == nullptr) {
    AHardwareBuffer_unlock(buffer, nullptr);
    return nullptr;
  }

  auto* dst = env->GetByteArrayElements(nv21, nullptr);

  // Copy Y plane (row by row to handle stride != width)
  auto* yData = static_cast<uint8_t*>(planes.planes[0].data);
  uint32_t yRowStride = planes.planes[0].rowStride;
  for (int row = 0; row < height; row++) {
    memcpy(dst + row * width, yData + row * yRowStride, width);
  }

  // Copy UV as interleaved VU (NV21 format)
  auto* uData = static_cast<uint8_t*>(planes.planes[1].data);
  auto* vData = static_cast<uint8_t*>(planes.planes[2].data);
  uint32_t uvRowStride = planes.planes[1].rowStride;
  uint32_t uvPixelStride = planes.planes[1].pixelStride;

  int uvOffset = ySize;
  for (int row = 0; row < height / 2; row++) {
    for (int col = 0; col < width / 2; col++) {
      dst[uvOffset++] = static_cast<jbyte>(vData[row * uvRowStride + col * uvPixelStride]);
      dst[uvOffset++] = static_cast<jbyte>(uData[row * uvRowStride + col * uvPixelStride]);
    }
  }

  env->ReleaseByteArrayElements(nv21, dst, 0);
  AHardwareBuffer_unlock(buffer, nullptr);

  return nv21;
#else
  return nullptr;
#endif
}

}
