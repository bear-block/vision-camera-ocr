// Mock react-native-vision-camera
jest.mock('react-native-vision-camera', () => {
  const mockPluginInstance = {
    call: jest.fn(),
  };
  return {
    VisionCameraProxy: {
      initFrameProcessorPlugin: jest.fn(() => mockPluginInstance),
    },
  };
});

import { performOcr, type OcrOptions, type OcrResult } from '../index';
import { VisionCameraProxy } from 'react-native-vision-camera';

describe('@bear-block/vision-camera-ocr', () => {
  const mockFrame = {
    width: 1920,
    height: 1080,
  } as any;

  // Get the mocked plugin instance
  const getMockPlugin = () => {
    return VisionCameraProxy.initFrameProcessorPlugin('detectText', {}) as any;
  };

  beforeEach(() => {
    jest.clearAllMocks();
    const plugin = getMockPlugin();
    plugin.call.mockReturnValue({ text: 'test text' });
  });

  describe('performOcr', () => {
    it('should export performOcr function', () => {
      expect(performOcr).toBeDefined();
      expect(typeof performOcr).toBe('function');
    });

    it('should call plugin with frame and empty options when options not provided', () => {
      const plugin = getMockPlugin();
      performOcr(mockFrame);
      expect(plugin.call).toHaveBeenCalledWith(mockFrame, {});
    });

    it('should call plugin with frame and provided options', () => {
      const plugin = getMockPlugin();
      const options: OcrOptions = {
        includeBoxes: true,
        includeConfidence: true,
      };
      performOcr(mockFrame, options);
      expect(plugin.call).toHaveBeenCalledWith(mockFrame, options);
    });

    it('should return result from plugin call', () => {
      const plugin = getMockPlugin();
      const result: OcrResult = {
        text: 'detected text',
        blocks: [
          {
            text: 'detected text',
            lines: [
              {
                text: 'detected text',
                words: [{ text: 'detected' }, { text: 'text' }],
              },
            ],
          },
        ],
      };
      plugin.call.mockReturnValue(result);

      const output = performOcr(mockFrame);
      expect(output).toEqual(result);
    });

    it('should return null when plugin returns null (no text detected)', () => {
      const plugin = getMockPlugin();
      plugin.call.mockReturnValue(null);
      const output = performOcr(mockFrame);
      expect(output).toBeNull();
    });

    it('should handle iOS-specific options', () => {
      const plugin = getMockPlugin();
      const options: OcrOptions = {
        recognitionLevel: 'accurate',
        recognitionLanguages: ['en-US', 'vi-VN'],
        usesLanguageCorrection: true,
      };
      performOcr(mockFrame, options);
      expect(plugin.call).toHaveBeenCalledWith(mockFrame, options);
    });

    it('should handle includeBoxes option', () => {
      const plugin = getMockPlugin();
      const resultWithBoxes: OcrResult = {
        text: 'test',
        blocks: [
          {
            text: 'test',
            box: { x: 0, y: 0, width: 100, height: 50 },
            lines: [
              {
                text: 'test',
                box: { x: 0, y: 0, width: 100, height: 50 },
                words: [
                  {
                    text: 'test',
                    box: { x: 0, y: 0, width: 50, height: 50 },
                  },
                ],
              },
            ],
          },
        ],
      };
      plugin.call.mockReturnValue(resultWithBoxes);

      const output = performOcr(mockFrame, { includeBoxes: true });
      expect(output).toEqual(resultWithBoxes);
      expect(output?.blocks).toBeDefined();
      expect(output?.blocks?.[0]?.box).toBeDefined();
    });

    it('should handle includeConfidence option', () => {
      const plugin = getMockPlugin();
      const resultWithConfidence: OcrResult = {
        text: 'test',
        blocks: [
          {
            text: 'test',
            lines: [
              {
                text: 'test',
                confidence: 0.95,
                words: [{ text: 'test', confidence: 0.95 }],
              },
            ],
          },
        ],
      };
      plugin.call.mockReturnValue(resultWithConfidence);

      const output = performOcr(mockFrame, { includeConfidence: true });
      expect(output).toEqual(resultWithConfidence);
    });
  });
});
