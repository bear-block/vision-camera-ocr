# @bear-block/vision-camera-ocr

<div align="center">

![React Native](https://img.shields.io/badge/React%20Native-0.79+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)

**A high-performance React Native Vision Camera plugin for real-time OCR (Optical Character Recognition)**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [API Reference](#-api-reference) • [Examples](#-examples) • [Contributing](#-contributing)

</div>

---

## 🚀 Overview

`@bear-block/vision-camera-ocr` is a powerful React Native library that provides real-time text recognition capabilities directly within your camera app. Built on top of `react-native-vision-camera`, it leverages native OCR engines for optimal performance:

- **Android**: Powered by Google ML Kit Text Recognition
- **iOS**: Powered by Apple's Vision Framework

Perfect for applications requiring real-time text extraction, document scanning, business card readers, or any OCR functionality.

## ✨ Features

- 🔥 **Real-time Processing** - Instant text recognition from camera frames
- 📱 **Cross-platform** - Native implementation for both Android & iOS
- 🚀 **High Performance** - Optimized native APIs with minimal overhead
- 🌐 **Offline First** - No internet connection required, all processing on-device
- 🎯 **Easy Integration** - Simple API that works seamlessly with Vision Camera
- 📊 **Configurable** - Support for different recognition models and options
- 🛡️ **Production Ready** - Built with TypeScript and comprehensive error handling

## 📦 Installation

### Prerequisites

- React Native 0.79+
- `react-native-vision-camera` >= 3.0
- `react-native-worklets-core` ^1.5.0

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

No additional setup required - the package is auto-linked.

## 🎯 Quick Start

### Basic Usage

```typescript
import { Camera, useFrameProcessor } from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';

function MyCameraComponent() {
  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const result = performOcr(frame);
    if (result?.text) {
      console.log('Detected text:', result.text);
    }
  }, []);

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

### Advanced Usage with Error Handling

```typescript
import { Camera, useFrameProcessor } from 'react-native-vision-camera';
import { performOcr } from '@bear-block/vision-camera-ocr';

function AdvancedCameraComponent() {
  const [detectedText, setDetectedText] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState(false);

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    try {
      setIsProcessing(true);
      const result = performOcr(frame);

      if (result?.text) {
        setDetectedText(result.text);
        // You can also send to your app's state management
        runOnJS(handleTextDetected)(result.text);
      }
    } catch (error) {
      console.error('OCR processing error:', error);
    } finally {
      setIsProcessing(false);
    }
  }, []);

  const handleTextDetected = (text: string) => {
    // Handle the detected text in your app
    console.log('New text detected:', text);
  };

  return (
    <View style={styles.container}>
      <Camera
        style={StyleSheet.absoluteFill}
        device={device}
        isActive={true}
        frameProcessor={frameProcessor}
        frameProcessorFps={3} // Lower FPS for better performance
      />

      {detectedText && (
        <View style={styles.textOverlay}>
          <Text style={styles.text}>{detectedText}</Text>
        </View>
      )}

      {isProcessing && (
        <View style={styles.processingIndicator}>
          <Text>Processing...</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
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
  processingIndicator: {
    position: 'absolute',
    top: 50,
    alignSelf: 'center',
    backgroundColor: 'rgba(0,0,0,0.7)',
    padding: 10,
    borderRadius: 20,
  },
});
```

## 📚 API Reference

### `performOcr(frame: Frame, options?: OcrOptions): OcrResult | null`

Performs OCR on a camera frame and returns recognized text with optional structure. Returns `null` when no text is detected.

#### Parameters

- `frame` (Frame): The camera frame to process from `react-native-vision-camera`
- `options` (optional):
  - `includeBoxes?: boolean` — include normalized bounding boxes for blocks/lines/words
  - `includeConfidence?: boolean` — include confidence scores when available (iOS lines)
  - `recognitionLevel?: 'fast' | 'accurate'` (iOS) — control Vision request speed/accuracy
  - `recognitionLanguages?: string[]` (iOS) — language hints, e.g. `["en-US", "vi-VN"]`
  - `usesLanguageCorrection?: boolean` (iOS) — enable language correction

#### Returns

- `OcrResult | null`:
  - `text: string` — concatenated recognized text
  - `blocks?: OcrBlock[]` — present when `includeBoxes` is true
    - `OcrBlock`: `{ text: string, box?: OcrBox, lines?: OcrLine[] }`
    - `OcrLine`: `{ text: string, box?: OcrBox, words?: OcrWord[], confidence?: number }`
    - `OcrWord`: `{ text: string, box?: OcrBox, confidence?: number }`
    - `OcrBox`: `{ x: number, y: number, width: number, height: number }` (normalized 0..1 on iOS; absolute px on Android for now)

#### Example

```typescript
const result = performOcr(frame, {
  includeBoxes: true,
  includeConfidence: true,
  recognitionLevel: 'accurate', // iOS
  recognitionLanguages: ['en-US', 'vi-VN'], // iOS
  usesLanguageCorrection: true, // iOS
});
if (result) {
  console.log('Detected text:', result.text);
  const firstLine = result.blocks?.[0]?.lines?.[0];
  if (firstLine?.box) {
    // Use normalized box on iOS (0..1). Android currently returns pixel units.
    console.log('First line box:', firstLine.box);
  }
} else {
  console.log('No text detected');
}
```

## 🔧 Configuration

### Frame Processor Options

Runtime `performOcr` options are recommended (see above). Initialization options are currently limited and not required.

> Note: Android uses ML Kit Latin text recognizer by default. iOS options map to Apple's Vision.

## 📱 Platform-Specific Details

### Android

- Uses Google ML Kit Text Recognition
- Optimized for Latin script languages
- Automatic language detection
- Fast processing with minimal memory usage
- Bounding boxes returned in pixel units (subject to change to normalized in future)

### iOS

- Uses Apple's Vision Framework
- Native integration with iOS camera system
- Support for multiple text recognition languages
- Optimized for iOS performance characteristics
- Supports `recognitionLevel`, `recognitionLanguages`, `usesLanguageCorrection`
- Bounding boxes returned normalized (0..1); y-origin is top-left in returned box structure

## 🎨 Use Cases

This library is perfect for:

- **Document Scanners** - Convert paper documents to digital text
- **Business Card Readers** - Extract contact information from business cards
- **Receipt Scanners** - Automate expense tracking and receipt processing
- **Text Translation Apps** - Real-time text recognition for translation
- **Accessibility Tools** - Help visually impaired users read text
- **Form Processing** - Automate data entry from paper forms
- **License Plate Recognition** - Vehicle identification systems
- **Product Label Scanners** - Extract information from product packaging

## 🚀 Performance Tips

- **Frame Rate**: Use `frameProcessorFps={3-5}` for optimal performance
- **Error Handling**: Always wrap OCR calls in try-catch blocks
- **State Management**: Debounce text updates to avoid excessive re-renders
- **Memory**: Process frames efficiently and avoid storing large amounts of data

## 🔧 Troubleshooting

### Android Issues

#### Plugin Not Found / "Failed to load Frame Processor Plugin"

**Problem:** The frame processor plugin isn't being registered properly.

**Solutions:**

1. **Clean and rebuild:**

   ```bash
   cd android
   ./gradlew clean
   cd ..
   # Then rebuild your app
   ```

2. **Verify auto-linking:**

   - Check that `react-native.config.js` exists in your project root
   - Ensure the package is listed in `package.json` dependencies
   - Run `npx react-native config` to verify the package is detected

3. **Manual linking (if auto-linking fails):**

   - Add to `android/settings.gradle`:
     ```gradle
     include ':vision-camera-ocr'
     project(':vision-camera-ocr').projectDir = new File(rootProject.projectDir, '../node_modules/@bear-block/vision-camera-ocr/android')
     ```
   - Add to `android/app/build.gradle` dependencies:
     ```gradle
     implementation project(':vision-camera-ocr')
     ```

4. **Check React Native version:**

   - Ensure you're using React Native 0.79+ (check `package.json`)
   - Verify `react-native-vision-camera` >= 3.0 is installed
   - Verify `react-native-worklets-core` ^1.5.0 is installed

5. **Verify ML Kit dependency:**
   - The library uses Google ML Kit Text Recognition
   - Ensure your `android/build.gradle` has Google Maven repository:
     ```gradle
     repositories {
       google()
       mavenCentral()
     }
     ```

#### Camera Permission Issues

**Problem:** Camera permission is denied or not requested.

**Solutions:**

1. Add to `AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-feature android:name="android.hardware.camera" android:required="true" />
   ```

2. Request permission at runtime (React Native 0.79+):

   ```typescript
   import { PermissionsAndroid } from 'react-native';

   const granted = await PermissionsAndroid.request(
     PermissionsAndroid.PERMISSIONS.CAMERA
   );
   ```

#### Build Errors

**Problem:** Gradle build fails with dependency or compilation errors.

**Solutions:**

1. **Update Gradle:**

   - Ensure Android Gradle Plugin 8.7.2+ is used
   - Check `android/build.gradle` for correct versions

2. **Clean build:**

   ```bash
   cd android
   ./gradlew clean
   rm -rf .gradle
   cd ..
   ```

3. **Check minSdkVersion:**
   - Library requires minSdkVersion 24
   - Verify in `android/build.gradle`:
     ```gradle
     minSdkVersion 24
     ```

### iOS Issues

#### Pod Install Fails

**Solutions:**

1. Update CocoaPods: `sudo gem install cocoapods`
2. Clean pods: `cd ios && pod deintegrate && pod install`
3. Clear cache: `rm -rf ~/Library/Caches/CocoaPods`

#### Camera Permission

**Solutions:**

1. Add to `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs access to your camera to perform OCR</string>
   ```

### General Issues

#### No Text Detected

**Solutions:**

1. Ensure good lighting conditions
2. Hold camera steady and focus on text
3. Try adjusting `frameProcessorFps` (lower values may help)
4. Check that text is clear and not too small
5. Verify the frame processor is being called (add console logs)

#### Performance Issues

**Solutions:**

1. Reduce `frameProcessorFps` to 2-3
2. Add throttling/debouncing to text updates
3. Process frames conditionally (e.g., only when camera is focused)
4. Avoid heavy operations in the frame processor worklet

## 📱 Example App

A complete working example app is available in the [`example`](./example) directory. See the [example README](./example/README.md) for setup instructions.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/bear-block/vision-camera-ocr.git
cd vision-camera-ocr

# Install dependencies
yarn install

# Run tests
yarn test

# Type checking
yarn typecheck

# Linting
yarn lint
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of [react-native-vision-camera](https://github.com/mrousavy/react-native-vision-camera)
- Android OCR powered by [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition)
- iOS OCR powered by [Apple Vision Framework](https://developer.apple.com/documentation/vision)

## 💖 Support This Project

If you find this library useful and would like to support ongoing development, please consider:

- ⭐ **Starring** this repository
- 🐛 **Reporting bugs** and feature requests
- 💻 **Contributing** code improvements
- 💰 **Sponsoring** us on GitHub

👉 [**Become a Sponsor**](https://github.com/sponsors/bear-block)

---

<div align="center">

**Made with ❤️ by [Bear Block](https://github.com/bear-block)**

[GitHub](https://github.com/bear-block) • [Issues](https://github.com/bear-block/vision-camera-ocr/issues) • [Discussions](https://github.com/bear-block/vision-camera-ocr/discussions)

</div>
