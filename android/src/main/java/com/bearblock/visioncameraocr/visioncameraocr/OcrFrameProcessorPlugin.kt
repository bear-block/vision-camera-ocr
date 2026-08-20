package com.bearblock.visioncameraocr.visioncameraocr

import android.graphics.Point
import android.graphics.Rect
import android.media.Image
import android.util.Log
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.mrousavy.camera.frameprocessors.Frame
import com.mrousavy.camera.frameprocessors.FrameProcessorPlugin
import com.mrousavy.camera.frameprocessors.VisionCameraProxy
import java.util.HashMap

class OcrFrameProcessorPlugin(
  proxy: VisionCameraProxy,
  private val options: Map<String, Any>?
) : FrameProcessorPlugin() {

  private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

  override fun callback(frame: Frame, arguments: Map<String, Any>?): HashMap<String, Any>? {
    val data = WritableNativeMap()

    // Log the options for debugging
    if (options != null) {
      Log.d("OcrDetector", "Plugin options: $options")
      val model = options["model"] as? String
      if (model != null) {
        Log.d("OcrDetector", "Using model: $model")
        // TODO: Implement different model options based on 'model' parameter
        // Currently ML Kit only supports DEFAULT_OPTIONS for text recognition
        // Future versions might support different accuracy/speed trade-offs
      }
    }

    // Read call-time arguments
    val includeBoxes = (arguments?.get("includeBoxes") as? Boolean) ?: false
    val includeConfidence = (arguments?.get("includeConfidence") as? Boolean) ?: false
    Log.d("OcrDetector", "Args includeBoxes=$includeBoxes includeConfidence=$includeConfidence")

    val mediaImage: Image = frame.image
    val image = InputImage.fromMediaImage(mediaImage, frame.imageProxy.imageInfo.rotationDegrees)

    return try {
      val visionText: Text = Tasks.await(recognizer.process(image))

      if (visionText.text.isEmpty()) {
        return null
      }

      data.putString("text", visionText.text)

      if (includeBoxes) {
        val blocksArray = WritableNativeArray()
        for (block in visionText.textBlocks) {
          val blockMap = WritableNativeMap()
          blockMap.putString("text", block.text)

          val blockRect: Rect? = block.boundingBox
          if (blockRect != null) {
            val boxMap = WritableNativeMap()
            boxMap.putDouble("x", blockRect.left.toDouble())
            boxMap.putDouble("y", blockRect.top.toDouble())
            boxMap.putDouble("width", (blockRect.right - blockRect.left).toDouble())
            boxMap.putDouble("height", (blockRect.bottom - blockRect.top).toDouble())
            blockMap.putMap("box", boxMap)
          }

          val linesArray = WritableNativeArray()
          for (line in block.lines) {
            val lineMap = WritableNativeMap()
            lineMap.putString("text", line.text)

            val lineRect: Rect? = line.boundingBox
            if (lineRect != null) {
              val lbox = WritableNativeMap()
              lbox.putDouble("x", lineRect.left.toDouble())
              lbox.putDouble("y", lineRect.top.toDouble())
              lbox.putDouble("width", (lineRect.right - lineRect.left).toDouble())
              lbox.putDouble("height", (lineRect.bottom - lineRect.top).toDouble())
              lineMap.putMap("box", lbox)
            }

            val wordsArray = WritableNativeArray()
            for (element in line.elements) {
              val wordMap = WritableNativeMap()
              wordMap.putString("text", element.text)
              val wRect: Rect? = element.boundingBox
              if (wRect != null) {
                val wbox = WritableNativeMap()
                wbox.putDouble("x", wRect.left.toDouble())
                wbox.putDouble("y", wRect.top.toDouble())
                wbox.putDouble("width", (wRect.right - wRect.left).toDouble())
                wbox.putDouble("height", (wRect.bottom - wRect.top).toDouble())
                wordMap.putMap("box", wbox)
              }
              wordsArray.pushMap(wordMap)
            }
            if (wordsArray.size() > 0) {
              lineMap.putArray("words", wordsArray)
            }
            linesArray.pushMap(lineMap)
          }
          if (linesArray.size() > 0) {
            blockMap.putArray("lines", linesArray)
          }
          blocksArray.pushMap(blockMap)
        }
        data.putArray("blocks", blocksArray)
      }

      @Suppress("UNCHECKED_CAST")
      data.toHashMap() as HashMap<String, Any>
    } catch (e: Exception) {
      Log.e("OcrDetector", "OCR recognition error: ${e.localizedMessage}")
      null
    }
  }
}
