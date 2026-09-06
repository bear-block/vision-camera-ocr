package com.margelo.nitro.visioncameraocr

import android.graphics.Rect
import android.net.Uri
import android.util.Log
import com.bearblock.visioncameraocr.OcrNativeHelper
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.margelo.nitro.NitroModules
import com.margelo.nitro.core.Promise
import java.io.File

class HybridOcrProcessor : HybridOcrProcessorSpec() {
  private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

  override val memorySize: Long
    get() = 128

  override fun performOcr(
    bufferAddress: ULong,
    width: Double,
    height: Double,
    orientation: String,
    includeBoxes: Boolean,
    includeConfidence: Boolean,
    recognitionLevel: String
  ): OcrResult? {
    return try {
      val w = width.toInt()
      val h = height.toInt()

      val nv21 = OcrNativeHelper.hardwareBufferToNv21(bufferAddress.toLong(), w, h)
        ?: return null

      val inputImage = InputImage.fromByteArray(nv21, w, h, 90, InputImage.IMAGE_FORMAT_NV21)
      recognize(inputImage, includeBoxes, includeConfidence)
    } catch (e: Exception) {
      Log.e(TAG, "OCR processing error: ${e.localizedMessage}")
      null
    }
  }

  override fun performOcrOnImage(
    imageUri: String,
    includeBoxes: Boolean,
    includeConfidence: Boolean,
    recognitionLevel: String,
  ): Promise<OcrResult> = Promise.parallel {
    val context = NitroModules.applicationContext
      ?: throw IllegalStateException("NitroModules application context is unavailable.")
    require(imageUri.isNotBlank()) { "The image URI must not be empty." }

    val parsedUri = Uri.parse(imageUri)
    val uri = when (parsedUri.scheme?.lowercase()) {
      null -> {
        val file = File(imageUri)
        require(file.isAbsolute) { "Static image path must be absolute: $imageUri" }
        Uri.fromFile(file)
      }
      "content", "file" -> parsedUri
      else -> throw IllegalArgumentException(
        "Static image URI must use the file or content scheme: $imageUri"
      )
    }

    val inputImage = InputImage.fromFilePath(context, uri)
    recognize(inputImage, includeBoxes, includeConfidence)
      ?: OcrResult(text = "", blocks = emptyArray())
  }

  private fun recognize(
    inputImage: InputImage,
    includeBoxes: Boolean,
    includeConfidence: Boolean,
  ): OcrResult? = synchronized(recognizer) {
    val visionText: Text = Tasks.await(recognizer.process(inputImage))

    if (visionText.text.isEmpty()) return@synchronized null

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
