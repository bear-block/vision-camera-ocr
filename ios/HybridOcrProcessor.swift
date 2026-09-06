import Foundation
import Vision
import CoreImage
import ImageIO
import NitroModules

class HybridOcrProcessor: HybridOcrProcessorSpec {
  var memorySize: Int { return 0 }

  private let staticImageQueue = DispatchQueue(
    label: "com.bearblock.visioncameraocr.static-image"
  )

  func performOcr(
    bufferAddress: UInt64,
    width: Double,
    height: Double,
    orientation: String,
    includeBoxes: Bool,
    includeConfidence: Bool,
    recognitionLevel: String
  ) throws -> OcrResult? {
    let pointer = UInt(truncatingIfNeeded: bufferAddress)
    guard let rawPointer = UnsafeRawPointer(bitPattern: pointer) else {
      return nil
    }
    let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(rawPointer).takeUnretainedValue()

    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .right, options: [:])

    return try recognize(
      handler: handler,
      includeBoxes: includeBoxes,
      includeConfidence: includeConfidence,
      recognitionLevel: recognitionLevel
    )
  }

  func performOcrOnImage(
    imageUri: String,
    includeBoxes: Bool,
    includeConfidence: Bool,
    recognitionLevel: String
  ) throws -> Promise<OcrResult> {
    return Promise.parallel(staticImageQueue) {
      let imageUrl = try self.resolveLocalImageUrl(imageUri)
      let orientation = self.imageOrientation(at: imageUrl)
      let handler = VNImageRequestHandler(
        url: imageUrl,
        orientation: orientation,
        options: [:]
      )

      return try self.recognize(
        handler: handler,
        includeBoxes: includeBoxes,
        includeConfidence: includeConfidence,
        recognitionLevel: recognitionLevel
      ) ?? OcrResult(text: "", blocks: [])
    }
  }

  private func recognize(
    handler: VNImageRequestHandler,
    includeBoxes: Bool,
    includeConfidence: Bool,
    recognitionLevel: String
  ) throws -> OcrResult? {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = recognitionLevel == "accurate" ? .accurate : .fast

    try handler.perform([request])

    guard let observations = request.results, !observations.isEmpty else {
      return nil
    }

    var lineResults: [(text: String, confidence: Float, box: CGRect?)] = []
    for observation in observations {
      guard let topCandidate = observation.topCandidates(1).first else { continue }
      let box = includeBoxes ? observation.boundingBox : nil
      lineResults.append((
        text: topCandidate.string,
        confidence: topCandidate.confidence,
        box: box
      ))
    }

    if lineResults.isEmpty {
      return nil
    }

    let joinedText = lineResults.map { $0.text }.joined(separator: " ")

    let lines: [OcrLine] = lineResults.map { line in
      let ocrBox: OcrBox? = line.box.map { rect in
        OcrBox(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
      }
      return OcrLine(
        text: line.text,
        box: ocrBox,
        words: [],
        confidence: includeConfidence ? Double(line.confidence) : 0
      )
    }

    let block = OcrBlock(
      text: joinedText,
      box: nil,
      lines: lines
    )

    return OcrResult(text: joinedText, blocks: [block])
  }

  private func resolveLocalImageUrl(_ imageUri: String) throws -> URL {
    let imageUrl: URL
    if let url = URL(string: imageUri), let scheme = url.scheme {
      guard scheme == "file" else {
        throw RuntimeError.error(
          withMessage: "Static image URI must use the file scheme on iOS: \(imageUri)"
        )
      }
      imageUrl = url
    } else {
      guard imageUri.hasPrefix("/") else {
        throw RuntimeError.error(
          withMessage: "Static image URI must be a file URL or absolute path: \(imageUri)"
        )
      }
      imageUrl = URL(fileURLWithPath: imageUri)
    }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(
      atPath: imageUrl.path,
      isDirectory: &isDirectory
    ), !isDirectory.boolValue else {
      throw RuntimeError.error(withMessage: "Static image file does not exist: \(imageUrl.path)")
    }
    guard FileManager.default.isReadableFile(atPath: imageUrl.path) else {
      throw RuntimeError.error(withMessage: "Static image file is not readable: \(imageUrl.path)")
    }

    return imageUrl
  }

  private func imageOrientation(at imageUrl: URL) -> CGImagePropertyOrientation {
    guard
      let source = CGImageSourceCreateWithURL(imageUrl as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let rawValue = properties[kCGImagePropertyOrientation] as? NSNumber,
      let orientation = CGImagePropertyOrientation(rawValue: rawValue.uint32Value)
    else {
      return .up
    }
    return orientation
  }
}
