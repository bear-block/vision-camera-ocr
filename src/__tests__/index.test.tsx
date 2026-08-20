// Mock react-native-nitro-modules
jest.mock('react-native-nitro-modules', () => {
  const mockProcessor = {
    performOcr: jest.fn(),
    name: 'OcrProcessor',
    toString: () => '[HybridObject OcrProcessor]',
    equals: jest.fn(),
    dispose: jest.fn(),
  };
  return {
    NitroModules: {
      createHybridObject: jest.fn(() => mockProcessor),
    },
  };
});

import { performOcr, type OcrOptions, type OcrResult } from '../index';
import { NitroModules } from 'react-native-nitro-modules';

describe('@bear-block/vision-camera-ocr', () => {
  const getMockProcessor = () => {
    return NitroModules.createHybridObject('OcrProcessor') as any;
  };

  beforeEach(() => {
    jest.clearAllMocks();
    const processor = getMockProcessor();
    processor.performOcr.mockReturnValue({ text: 'test text', blocks: [] });
  });

  describe('performOcr', () => {
    it('should export performOcr function', () => {
      expect(performOcr).toBeDefined();
      expect(typeof performOcr).toBe('function');
    });

    it('should call processor with correct arguments when options not provided', () => {
      const processor = getMockProcessor();
      performOcr(12345, 1920, 1080, 'up');
      expect(processor.performOcr).toHaveBeenCalledWith(
        BigInt(12345),
        1920,
        1080,
        'up',
        false,
        false,
        'fast'
      );
    });

    it('should call processor with provided options', () => {
      const processor = getMockProcessor();
      const options: OcrOptions = {
        includeBoxes: true,
        includeConfidence: true,
        recognitionLevel: 'accurate',
      };
      performOcr(12345, 1920, 1080, 'up', options);
      expect(processor.performOcr).toHaveBeenCalledWith(
        BigInt(12345),
        1920,
        1080,
        'up',
        true,
        true,
        'accurate'
      );
    });

    it('should return result from processor', () => {
      const processor = getMockProcessor();
      const result: OcrResult = {
        text: 'detected text',
        blocks: [
          {
            text: 'detected text',
            box: undefined,
            lines: [
              {
                text: 'detected text',
                box: undefined,
                words: [
                  { text: 'detected', box: undefined, confidence: 0 },
                  { text: 'text', box: undefined, confidence: 0 },
                ],
                confidence: 0,
              },
            ],
          },
        ],
      };
      processor.performOcr.mockReturnValue(result);

      const output = performOcr(12345, 1920, 1080, 'up');
      expect(output).toEqual(result);
    });

    it('should return null when processor returns undefined', () => {
      const processor = getMockProcessor();
      processor.performOcr.mockReturnValue(undefined);
      const output = performOcr(12345, 1920, 1080, 'up');
      expect(output).toBeNull();
    });

    it('should handle bigint buffer pointer', () => {
      const processor = getMockProcessor();
      performOcr(BigInt(12345), 1920, 1080, 'up');
      expect(processor.performOcr).toHaveBeenCalledWith(
        BigInt(12345),
        1920,
        1080,
        'up',
        false,
        false,
        'fast'
      );
    });
  });
});
