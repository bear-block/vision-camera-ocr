import Foundation
import Vision
import CoreImage
import NitroModules

class HybridOcrProcessor: HybridOcrProcessorSpec {
  var hybridContext = margelo.nitro.HybridContext()
  var memorySize: Int { return getSizeOf(self) }

  func performOcr(
    bufferAddress: Double,
    width: Double,
    height: Double,
    orientation: String,
    includeBoxes: Bool,
    includeConfidence: Bool,
    recognitionLevel: String
  ) throws -> OcrResult? {
    let pointer = UInt(bufferAddress)
    guard let rawPointer = UnsafeRawPointer(bitPattern: pointer) else {
      return nil
    }
    let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(rawPointer).takeUnretainedValue()

    guard let ciImage = CIImage(cvPixelBuffer: pixelBuffer) else {
      return nil
    }

    let cgOrientation = mapOrientation(orientation)
    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: cgOrientation, options: [:])

    let request = VNRecognizeTextRequest()
    if recognitionLevel == "accurate" {
      request.recognitionLevel = .accurate
    } else {
      request.recognitionLevel = .fast
    }

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

  private func mapOrientation(_ orientation: String) -> CGImagePropertyOrientation {
    switch orientation {
    case "up": return .up
    case "down": return .down
    case "left": return .left
    case "right": return .right
    default: return .up
    }
  }
}
