/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:platform_ocr/platform_ocr.dart' show OcrSource;
import 'package:platform_ocr/src/platform_ocr_interface.dart' show PlatformOcr;

export 'src/platform_ocr_interface.dart';

/// Recognizes text from an [OcrSource] using the platform's native OCR engine.
///
/// This is a convenience function that creates a [PlatformOcr] instance,
/// performs the recognition, and disposes of the instance automatically.
/// For multiple recognitions, it's more efficient to create a [PlatformOcr]
/// instance and reuse it.
Future<String> recognizeText(OcrSource source) async {
  final ocr = PlatformOcr();
  try {
    return await ocr.recognizeText(source);
  } finally {
    ocr.dispose();
  }
}
