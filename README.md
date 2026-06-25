# @bear-block/vision-camera-ocr

<div align="center">

![React Native](https://img.shields.io/badge/React%20Native-0.79+-blue.svg)
![Vision Camera](https://img.shields.io/badge/Vision%20Camera-v3%20%7C%20v4-purple.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)

**A high-performance React Native Vision Camera plugin for real-time OCR (Optical Character Recognition)**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [API Reference](#-api-reference) • [Contributing](#-contributing)

</div>

---

## Version Compatibility

| Package version | VisionCamera version | Status |
|---|---|---|
| **4.x** (this) | v3 / v4 | **Stable** |
| **5.x** | v5 | Coming soon |

> ### Using VisionCamera v5?
>
> VisionCamera v5 introduced a completely new architecture (Nitro Modules) and removed the Frame Processor Plugin system used by this package. **This version (4.x) is NOT compatible with VisionCamera v5.**
>
> Install the v5-compatible version instead:
>
> ```bash
> yarn add @bear-block/vision-camera-ocr@5
> ```
>
> See the [v5 migration guide](https://github.com/bear-block/vision-camera-ocr/tree/support/v5#-migrating-from-v1) for details.

---

## Overview

`@bear-block/vision-camera-ocr` is a powerful React Native library that provides real-time text recognition capabilities directly within your camera app. Built on top of `react-native-vision-camera` v3/v4's Frame Processor Plugin system, it leverages native OCR engines for optimal performance:

- **Android**: Powered by Google ML Kit Text Recognition
- **iOS**: Powered by Apple's Vision Framework

Perfect for applications requiring real-time text extraction, document scanning, business card readers, or any OCR functionality.

## Features

- **Real-time Processing** — Instant text recognition from camera frames via worklets
- **Cross-platform** — Native implementation for both Android & iOS
- **High Performance** — Runs synchronously on the camera thread, zero bridge overhead
- **Offline First** — No internet connection required, all processing on-device
- **Easy Integration** — Simple `performOcr(frame)` API inside `useFrameProcessor`
- **Configurable** — Bounding boxes, confidence scores, recognition level, language hints
- **Production Ready** — Built with TypeScript and comprehensive error handling

## Installation

### Prerequisites

| Dependency | Version |
|---|---|
| React Native | 0.79+ |
| `react-native-vision-camera` | **^3.0.0 \|\| ^4.0.0** |
| `react-native-worklets-core` | ^1.5.0 |

### Install the package

```bash
# Using yarn (recommended)
yarn add @bear-block/vision-camera-ocr

# Using npm
npm install @bear-block/vision-camera-ocr

# Using pnpm
pnpm add @bear-block/vision-camera-ocr
```

### iOS Setup

```bash
cd ios && pod install
```

### Android Setup

No additional setup required — the package is auto-linked.

## Quick Start

### Basic Usage

```typescript
import { Camera, useFrameProcessor } from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';

function MyCameraComponent() {
  const device = useCameraDevice('back');

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const result = performOcr(frame);
    if (result?.text) {
      console.log('Detected text:', result.text);
    }
  }, []);

  if (device == null) return null;

  return (
    <Camera
      style={StyleSheet.absoluteFill}
      device={device}
      isActive={true}
      frameProcessor={frameProcessor}
      frameProcessorFps={5}
    />
  );
}
```

### Advanced Usage

```typescript
import { Camera, useFrameProcessor } from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';
import { runOnJS } from 'react-native-worklets-core';

function AdvancedCameraComponent() {
  const device = useCameraDevice('back');
  const [detectedText, setDetectedText] = useState('');

  const handleText = useCallback((text: string) => {
    setDetectedText(text);
  }, []);

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const result = performOcr(frame, {
      includeBoxes: true,
      includeConfidence: true,
      recognitionLevel: 'accurate', // iOS only
    });

    if (result?.text) {
      runOnJS(handleText)(result.text);
    }
  }, [handleText]);

  if (device == null) return null;

  return (
    <View style={styles.container}>
      <Camera
        style={StyleSheet.absoluteFill}
        device={device}
        isActive={true}
        frameProcessor={frameProcessor}
        frameProcessorFps={3}
      />

      {detectedText ? (
        <View style={styles.textOverlay}>
          <Text style={styles.text}>{detectedText}</Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  textOverlay: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(0,0,0,0.7)',
    padding: 15,
    borderRadius: 10,
  },
  text: {
    color: 'white',
    fontSize: 16,
    textAlign: 'center',
  },
});
```

## API Reference

### `performOcr(frame, options?)`

Performs OCR on a camera frame and returns recognized text. Runs synchronously on the camera thread (worklet-compatible). Returns `null` when no text is detected.

#### Parameters

| Parameter | Type | Description |
|---|---|---|
| `frame` | `Frame` | The camera frame from `useFrameProcessor` |
| `options` | `OcrOptions` (optional) | See below |

#### OcrOptions

| Option | Type | Default | Platform | Description |
|---|---|---|---|---|
| `includeBoxes` | `boolean` | `false` | Both | Include bounding boxes for blocks, lines, and words |
| `includeConfidence` | `boolean` | `false` | Both | Include confidence scores |
| `recognitionLevel` | `'fast' \| 'accurate'` | `'fast'` | iOS | Vision framework recognition level |
| `recognitionLanguages` | `string[]` | — | iOS | Language hints, e.g. `['en-US', 'vi-VN']` |
| `usesLanguageCorrection` | `boolean` | — | iOS | Enable language correction |

#### Returns

`OcrResult | null`

```typescript
type OcrResult = {
  text: string;        // All recognized text concatenated
  blocks?: OcrBlock[]; // Present when includeBoxes is true
};

type OcrBlock = {
  text: string;
  box?: OcrBox;
  lines?: OcrLine[];
};

type OcrLine = {
  text: string;
  box?: OcrBox;
  words?: OcrWord[];
  confidence?: number;
};

type OcrWord = {
  text: string;
  box?: OcrBox;
  confidence?: number;
};

type OcrBox = {
  x: number;      // Normalized 0..1 on iOS, pixel units on Android
  y: number;
  width: number;
  height: number;
};
```

#### Example

```typescript
const result = performOcr(frame, {
  includeBoxes: true,
  includeConfidence: true,
  recognitionLevel: 'accurate',
  recognitionLanguages: ['en-US', 'vi-VN'],
  usesLanguageCorrection: true,
});

if (result) {
  console.log('Text:', result.text);
  const firstLine = result.blocks?.[0]?.lines?.[0];
  if (firstLine?.box) {
    console.log('First line box:', firstLine.box);
  }
}
```

## Platform-Specific Details

### Android

- Uses Google ML Kit Text Recognition
- Optimized for Latin script languages
- Automatic language detection
- Bounding boxes returned in pixel units

### iOS

- Uses Apple's Vision Framework
- Supports `recognitionLevel`, `recognitionLanguages`, `usesLanguageCorrection`
- Bounding boxes returned normalized (0..1)

## Performance Tips

- Use `frameProcessorFps={3-5}` for optimal performance
- Use `recognitionLevel: 'fast'` (default) for real-time, `'accurate'` for single captures
- Debounce text updates via `runOnJS` to avoid excessive re-renders
- Process frames conditionally (e.g., only when camera is focused)

## Troubleshooting

### "Failed to load Frame Processor Plugin"

1. Clean and rebuild:
   ```bash
   cd android && ./gradlew clean && cd ..
   cd ios && pod deintegrate && pod install && cd ..
   ```

2. Verify dependencies are installed:
   ```bash
   npx react-native config
   ```

3. Check that `react-native-worklets-core` is installed and linked.

### Camera Permission

**iOS** — Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to perform OCR</string>
```

**Android** — Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### No Text Detected

1. Ensure good lighting conditions
2. Hold camera steady and focus on text
3. Try `recognitionLevel: 'accurate'` for difficult text
4. Lower `frameProcessorFps` to give more time per frame

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/bear-block/vision-camera-ocr.git
cd vision-camera-ocr

yarn install
yarn test
yarn typecheck
yarn lint
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of [react-native-vision-camera](https://github.com/mrousavy/react-native-vision-camera) v3/v4
- Android OCR powered by [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition)
- iOS OCR powered by [Apple Vision Framework](https://developer.apple.com/documentation/vision)

---

<div align="center">

**Made with ❤️ by [Bear Block](https://github.com/bear-block)**

[GitHub](https://github.com/bear-block) • [Issues](https://github.com/bear-block/vision-camera-ocr/issues) • [Discussions](https://github.com/bear-block/vision-camera-ocr/discussions)

</div>
