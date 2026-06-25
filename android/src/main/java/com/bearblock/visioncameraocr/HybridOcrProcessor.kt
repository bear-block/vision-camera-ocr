package com.bearblock.visioncameraocr

import android.graphics.Bitmap
import android.graphics.ColorSpace
import android.graphics.Rect
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.margelo.nitro.visioncameraocr.HybridOcrProcessorSpec
import com.margelo.nitro.visioncameraocr.OcrBlock
import com.margelo.nitro.visioncameraocr.OcrBox
import com.margelo.nitro.visioncameraocr.OcrLine
import com.margelo.nitro.visioncameraocr.OcrResult
import com.margelo.nitro.visioncameraocr.OcrWord

class HybridOcrProcessor : HybridOcrProcessorSpec() {
  private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

  override val memorySize: Long
    get() = 128

  override fun performOcr(
    bufferAddress: Double,
    width: Double,
    height: Double,
    orientation: String,
    includeBoxes: Boolean,
    includeConfidence: Boolean,
    recognitionLevel: String
  ): OcrResult? {
    return try {
      val pointer = bufferAddress.toLong()
      val hardwareBuffer = OcrNativeHelper.pointerToHardwareBuffer(pointer)
        ?: return null

      val bitmap = Bitmap.wrapHardwareBuffer(hardwareBuffer, ColorSpace.get(ColorSpace.Named.SRGB))
      hardwareBuffer.close()

      if (bitmap == null) return null

      val rotationDegrees = when (orientation) {
        "up" -> 0
        "right" -> 90
        "down" -> 180
        "left" -> 270
        else -> 0
      }

      val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
      val visionText: Text = Tasks.await(recognizer.process(inputImage))

      if (visionText.text.isEmpty()) return null

      val blocks = visionText.textBlocks.map { block ->
        val blockBox = if (includeBoxes) block.boundingBox?.toOcrBox() else null

        val lines = block.lines.map { line ->
          val lineBox = if (includeBoxes) line.boundingBox?.toOcrBox() else null
          val words = line.elements.map { element ->
            val wordBox = if (includeBoxes) element.boundingBox?.toOcrBox() else null
            OcrWord(
              text = element.text,
              box = wordBox,
              confidence = if (includeConfidence) element.confidence.toDouble() else 0.0
            )
          }.toTypedArray()

          OcrLine(
            text = line.text,
            box = lineBox,
            words = words,
            confidence = if (includeConfidence) line.confidence.toDouble() else 0.0
          )
        }.toTypedArray()

        OcrBlock(
          text = block.text,
          box = blockBox,
          lines = lines
        )
      }.toTypedArray()

      OcrResult(text = visionText.text, blocks = blocks)
    } catch (e: Exception) {
      Log.e(TAG, "OCR processing error: ${e.localizedMessage}")
      null
    }
  }

  private fun Rect.toOcrBox(): OcrBox {
    return OcrBox(
      x = left.toDouble(),
      y = top.toDouble(),
      width = (right - left).toDouble(),
      height = (bottom - top).toDouble()
    )
  }

  companion object {
    private const val TAG = "HybridOcrProcessor"
  }
}
