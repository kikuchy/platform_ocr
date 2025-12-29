# platform_ocr

A high-performance, local OCR package for Dart and Flutter that leverages native OS APIs. This package directly utilizes the built-in OCR capabilities of Windows and Darwin (macOS/iOS) for optimal speed and accuracy without external dependencies like Tesseract.

## Features

- **Blazing Fast**: Uses native OS-optimized OCR models.
- **Local Processing**: No data is sent to the cloud, ensuring user privacy and offline support.
- **Platform Native**: Utilizes `Windows.Media.Ocr` on Windows and `Vision.framework` on Darwin.
- **Native Assets**: Seamless integration using Dart Native Assets for automated building and linking.

## Platform Support

| Platform | Native API | Status |
| :--- | :--- | :--- |
| **Windows** | `Windows.Media.Ocr` (WinRT) | ✅ Implemented |
| **iOS** | `Vision.framework` | ✅ Implemented |
| **macOS** | `Vision.framework` | ✅ Implemented |

> [!NOTE]
> Android is not supported as this package focuses on OCR features built directly into the OS. 

## Getting Started

### Prerequisites

- **Windows**: Visual Studio 2022 with "Desktop development with C++" and "C++/WinRT" components.
- **macOS/iOS**: Xcode with latest SDKs.

### Installation

Add `platform_ocr` to your `pubspec.yaml`:

```yaml
dependencies:
  platform_ocr: ^1.0.0
```

Since this package uses **Native Assets**, ensure you are using a compatible Flutter version (3.13+) and have the necessary build tools installed.

## Usage

```dart
import 'package:platform_ocr/platform_ocr.dart';

void main() async {
  final ocr = PlatformOcr();

  // From a file
  final textFromFile = await ocr.recognizeText(OcrSource.file(File('image.png')));
  print('Recognized: $textFromFile');

  // From memory
  final textFromMemory = await ocr.recognizeText(OcrSource.memory(uint8List));
  print('Recognized: $textFromMemory');
}
```

## Internal Architecture

### Windows
Implemented using C++/WinRT with a C ABI wrapper (`src/windows/ocr_cabi.cpp`). Images are decoded in Dart using `package:image` to ensure correct RGBA8 format delivery to the native engine.

### Darwin (iOS/macOS)
Implemented using direct Objective-C interop with `VNRecognizeTextRequest` from the Vision framework. It supports both path-based and memory-based (NSData) image processing.

## Roadmap

- [ ] Support for detection level (Fast vs. Accurate).
- [ ] Language specific hints.
- [ ] Bounding box information for recognized text.
- [ ] Transition to Windows Imaging Component (WIC) for native image decoding on Windows.

## License

BSD 3-Clause License

