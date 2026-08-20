import { NitroModules } from 'react-native-nitro-modules';
import type { OcrProcessor } from './specs/OcrProcessor.nitro';

export type {
  OcrBox,
  OcrWord,
  OcrLine,
  OcrBlock,
  OcrResult,
} from './specs/OcrProcessor.nitro';

export type OcrOptions = {
  includeBoxes?: boolean;
  includeConfidence?: boolean;
  recognitionLevel?: 'fast' | 'accurate';
};

const ocrProcessor =
  NitroModules.createHybridObject<OcrProcessor>('OcrProcessor');

/**
 * Performs OCR on a VisionCamera v5 Frame.
 *
 * Usage with useFrameOutput:
 * ```ts
 * import { performOcr } from '@bear-block/vision-camera-ocr'
 * import { useFrameOutput } from 'react-native-vision-camera'
 *
 * const frameOutput = useFrameOutput({
 *   onFrame(frame) {
 *     'worklet'
 *     if (!frame.hasNativeBuffer) {
 *       frame.dispose()
 *       return
 *     }
 *     const nativeBuffer = frame.getNativeBuffer()
 *     const result = performOcr(nativeBuffer.pointer, frame.width, frame.height, frame.orientation)
 *     nativeBuffer.release()
 *     frame.dispose()
 *     if (result) {
 *       // handle result via runOnJS or shared value
 *     }
 *   }
 * })
 * ```
 */
export function performOcr(
  bufferPointer: number | bigint,
  width: number,
  height: number,
  orientation: string,
  options?: OcrOptions
): import('./specs/OcrProcessor.nitro').OcrResult | null {
  'worklet';
  const result = ocrProcessor.performOcr(
    BigInt(bufferPointer),
    width,
    height,
    orientation,
    options?.includeBoxes ?? false,
    options?.includeConfidence ?? false,
    options?.recognitionLevel ?? 'fast'
  );
  return result ?? null;
}
