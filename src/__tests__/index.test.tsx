// Mock react-native-nitro-modules
jest.mock('react-native-nitro-modules', () => {
  const mockProcessor = {
    performOcr: jest.fn(),
    performOcrOnImage: jest.fn(),
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

import {
  performOcr,
  performOcrOnImage,
  type OcrOptions,
  type OcrResult,
} from '../index';
import { NitroModules } from 'react-native-nitro-modules';

describe('@bear-block/vision-camera-ocr', () => {
  const getMockProcessor = () => {
    return NitroModules.createHybridObject('OcrProcessor') as any;
  };

  beforeEach(() => {
    jest.clearAllMocks();
    const processor = getMockProcessor();
    processor.performOcr.mockReturnValue({ text: 'test text', blocks: [] });
    processor.performOcrOnImage.mockResolvedValue({
      text: 'static test text',
      blocks: [],
    });
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

  describe('performOcrOnImage', () => {
    it('should export performOcrOnImage function', () => {
      expect(performOcrOnImage).toBeDefined();
      expect(typeof performOcrOnImage).toBe('function');
    });

    it('should call processor with default options', async () => {
      const processor = getMockProcessor();

      await performOcrOnImage('file:///tmp/label.jpg');

      expect(processor.performOcrOnImage).toHaveBeenCalledWith(
        'file:///tmp/label.jpg',
        false,
        false,
        'fast'
      );
    });

    it('should call processor with provided options', async () => {
      const processor = getMockProcessor();
      const options: OcrOptions = {
        includeBoxes: true,
        includeConfidence: true,
        recognitionLevel: 'accurate',
      };

      await performOcrOnImage('content://media/label', options);

      expect(processor.performOcrOnImage).toHaveBeenCalledWith(
        'content://media/label',
        true,
        true,
        'accurate'
      );
    });

    it('should resolve the result from the processor', async () => {
      const processor = getMockProcessor();
      const result: OcrResult = { text: 'nutrition facts', blocks: [] };
      processor.performOcrOnImage.mockResolvedValue(result);

      await expect(performOcrOnImage('/tmp/label.jpg')).resolves.toEqual(
        result
      );
    });

    it('should reject an empty image URI before calling native code', async () => {
      const processor = getMockProcessor();

      await expect(performOcrOnImage('   ')).rejects.toThrow(
        'The image URI must not be empty.'
      );
      expect(processor.performOcrOnImage).not.toHaveBeenCalled();
    });
  });
});
