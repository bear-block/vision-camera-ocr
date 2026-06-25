# @bear-block/vision-camera-ocr

<div align="center">

![React Native](https://img.shields.io/badge/React%20Native-0.79+-blue.svg)
![Vision Camera](https://img.shields.io/badge/Vision%20Camera-v5-purple.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Version](https://img.shields.io/badge/version-5.0.0--beta.1-blue.svg)

**A high-performance React Native Vision Camera plugin for real-time OCR (Optical Character Recognition)**

[Features](#features) • [Installation](#installation) • [Migration](#migrating-from-v4) • [Usage](#quick-start) • [API Reference](#api-reference) • [Contributing](#contributing)

</div>

---

## Version Compatibility

| Package version | VisionCamera version | Status |
|---|---|---|
| **4.x** | v3 / v4 | Stable |
| **5.x** (this) | **v5** | **Beta** |

> ### Using VisionCamera v3 or v4?
>
> This version (5.x) is built for VisionCamera v5's Nitro Module architecture and is **NOT compatible with VisionCamera v3/v4**.
>
> Install the v4-compatible version instead:
>
> ```bash
> yarn add @bear-block/vision-camera-ocr@4
> ```

---

## Overview

`@bear-block/vision-camera-ocr` is a powerful React Native library that provides real-time text recognition capabilities directly within your camera app. Built as a [Nitro module](https://nitro.margelo.com/) for VisionCamera v5, it leverages native OCR engines for optimal performance:

- **Android**: Powered by Google ML Kit Text Recognition
- **iOS**: Powered by Apple's Vision Framework

## Features

- **Real-time Processing** — Instant text recognition from camera frames
- **Cross-platform** — Native implementation for both Android & iOS
- **High Performance** — Nitro module runs synchronously on the camera thread
- **Offline First** — No internet connection required, all processing on-device
- **Easy Integration** — Simple API that works with VisionCamera v5's `useFrameOutput`
- **Configurable** — Bounding boxes, confidence scores, recognition level options
- **Production Ready** — Built with TypeScript and comprehensive error handling

## Installation

### Prerequisites

| Dependency | Version |
|---|---|
| React Native | 0.79+ |
| `react-native-vision-camera` | **>= 5.0.0** |
| `react-native-nitro-modules` | >= 0.27.0 |
| `react-native-vision-camera-worklets` | >= 5.0.0 (for `useFrameOutput`) |

### Install the package

```bash
# Using yarn (recommended)
yarn add @bear-block/vision-camera-ocr@5

# Using npm
npm install @bear-block/vision-camera-ocr@5
```

### iOS Setup

```bash
cd ios && pod install
```

### Android Setup

No additional setup required — the package is auto-linked.

## Migrating from v4

v5 is a **breaking change** due to VisionCamera v5's complete architecture rewrite. The Frame Processor Plugin system (`VisionCameraProxy`, `useFrameProcessor`) no longer exists in VisionCamera v5.

### What changed

| v4.x (VisionCamera v3/v4) | v5.x (VisionCamera v5) |
|---|---|
| `useFrameProcessor` | `useFrameOutput` |
| `performOcr(frame)` | `performOcr(nativeBuffer.pointer, width, height, orientation)` |
| Frame Processor Plugin (JSI) | Nitro Module (Nitro) |
| `react-native-worklets-core` | `react-native-vision-camera-worklets` |

### Before (v4.x)

```typescript
import { Camera, useFrameProcessor } from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';

const frameProcessor = useFrameProcessor((frame) => {
  'worklet';
  const result = performOcr(frame);
}, []);

<Camera frameProcessor={frameProcessor} />
```

### After (v5.x)

```typescript
import { useCamera, useFrameOutput } from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';

const frameOutput = useFrameOutput({
  pixelFormat: 'native',
  onFrame(frame) {
    'worklet';
    if (!frame.hasNativeBuffer) {
      frame.dispose();
      return;
    }
    const nativeBuffer = frame.getNativeBuffer();
    const result = performOcr(
      nativeBuffer.pointer,
      frame.width,
      frame.height,
      frame.orientation
    );
    nativeBuffer.release();
    frame.dispose();
  },
});

const camera = useCamera({ outputs: [frameOutput] });
```

## Quick Start

### Basic Usage

```typescript
import React, { useCallback, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import {
  useCamera,
  useCameraDevice,
  useFrameOutput,
} from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';

function MyCameraComponent() {
  const device = useCameraDevice('back');
  const [detectedText, setDetectedText] = useState('');

  const frameOutput = useFrameOutput({
    pixelFormat: 'native',
    onFrame: useCallback((frame) => {
      'worklet';
      if (!frame.hasNativeBuffer) {
        frame.dispose();
        return;
      }
      const nativeBuffer = frame.getNativeBuffer();
      const result = performOcr(
        nativeBuffer.pointer,
        frame.width,
        frame.height,
        frame.orientation
      );
      nativeBuffer.release();
      frame.dispose();

      if (result?.text) {
        runOnJS(setDetectedText)(result.text);
      }
    }, []),
  });

  const camera = useCamera({ outputs: [frameOutput] });

  if (device == null) return null;

  return (
    <View style={StyleSheet.absoluteFill}>
      {camera.preview}
      {detectedText ? (
        <View style={styles.overlay}>
          <Text style={styles.text}>{detectedText}</Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
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

### With Bounding Boxes & Confidence

```typescript
const result = performOcr(
  nativeBuffer.pointer,
  frame.width,
  frame.height,
  frame.orientation,
  {
    includeBoxes: true,
    includeConfidence: true,
    recognitionLevel: 'accurate', // iOS only
  }
);

if (result) {
  console.log('Full text:', result.text);
  for (const block of result.blocks) {
    for (const line of block.lines) {
      console.log('Line:', line.text, 'confidence:', line.confidence);
    }
  }
}
```

## API Reference

### `performOcr(bufferPointer, width, height, orientation, options?)`

Performs OCR on a native buffer from a VisionCamera v5 Frame. Runs synchronously on the camera thread (worklet-compatible). Returns `null` when no text is detected.

#### Parameters

| Parameter | Type | Description |
|---|---|---|
| `bufferPointer` | `number \| bigint` | The `NativeBuffer.pointer` from `frame.getNativeBuffer()` |
| `width` | `number` | Frame width (`frame.width`) |
| `height` | `number` | Frame height (`frame.height`) |
| `orientation` | `string` | Frame orientation (`frame.orientation`): `'up'`, `'down'`, `'left'`, `'right'` |
| `options` | `OcrOptions` (optional) | See below |

#### OcrOptions

| Option | Type | Default | Description |
|---|---|---|---|
| `includeBoxes` | `boolean` | `false` | Include bounding boxes for blocks, lines, and words |
| `includeConfidence` | `boolean` | `false` | Include confidence scores |
| `recognitionLevel` | `'fast' \| 'accurate'` | `'fast'` | iOS only — Vision framework recognition level |

#### Returns

`OcrResult | null`

```typescript
interface OcrResult {
  text: string;
  blocks: OcrBlock[];
}

interface OcrBlock {
  text: string;
  box: OcrBox | undefined;
  lines: OcrLine[];
}

interface OcrLine {
  text: string;
  box: OcrBox | undefined;
  words: OcrWord[];
  confidence: number;  // 0 if includeConfidence is false
}

interface OcrWord {
  text: string;
  box: OcrBox | undefined;
  confidence: number;
}

interface OcrBox {
  x: number;      // Normalized 0..1 on iOS, pixel units on Android
  y: number;
  width: number;
  height: number;
}
```

## Platform-Specific Details

### Android

- Uses Google ML Kit Text Recognition
- Optimized for Latin script languages
- Bounding boxes returned in pixel units
- Requires `minSdkVersion` 26 (for HardwareBuffer support)

### iOS

- Uses Apple's Vision Framework
- `recognitionLevel: 'accurate'` provides better results but is slower
- Bounding boxes returned normalized (0..1)

## Performance Tips

- Use `pixelFormat: 'native'` in `useFrameOutput` for zero-copy performance
- Set `recognitionLevel: 'fast'` (default) for real-time, `'accurate'` for single captures
- Always call `nativeBuffer.release()` and `frame.dispose()` promptly
- Use `dropFramesWhileBusy: true` (default) to avoid frame queue buildup

## Troubleshooting

### Build Errors

**"NitroModules not found"** — Ensure `react-native-nitro-modules` is installed:

```bash
yarn add react-native-nitro-modules
cd ios && pod install
```

**"VisionCameraOcr module not found"** — Clean and rebuild:

```bash
cd ios && pod deintegrate && pod install && cd ..
cd android && ./gradlew clean && cd ..
```

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

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/bear-block/vision-camera-ocr.git
cd vision-camera-ocr
git checkout support/v5

yarn install
yarn codegen   # Run Nitrogen codegen after modifying specs
yarn test
yarn typecheck
yarn lint
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of [react-native-vision-camera v5](https://github.com/mrousavy/react-native-vision-camera)
- Powered by [Nitro Modules](https://nitro.margelo.com/)
- Android OCR powered by [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition)
- iOS OCR powered by [Apple Vision Framework](https://developer.apple.com/documentation/vision)

---

<div align="center">

**Made with ❤️ by [Bear Block](https://github.com/bear-block)**

[GitHub](https://github.com/bear-block) • [Issues](https://github.com/bear-block/vision-camera-ocr/issues) • [Discussions](https://github.com/bear-block/vision-camera-ocr/discussions)

</div>
