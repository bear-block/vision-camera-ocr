import type { HybridObject, UInt64 } from 'react-native-nitro-modules';

export interface OcrBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface OcrWord {
  text: string;
  box: OcrBox | undefined;
  confidence: number;
}

export interface OcrLine {
  text: string;
  box: OcrBox | undefined;
  words: OcrWord[];
  confidence: number;
}

export interface OcrBlock {
  text: string;
  box: OcrBox | undefined;
  lines: OcrLine[];
}

export interface OcrResult {
  text: string;
  blocks: OcrBlock[];
}

export interface OcrProcessor
  extends HybridObject<{ ios: 'swift'; android: 'kotlin' }> {
  performOcr(
    bufferAddress: UInt64,
    width: number,
    height: number,
    orientation: string,
    includeBoxes: boolean,
    includeConfidence: boolean,
    recognitionLevel: string
  ): OcrResult | undefined;
}
