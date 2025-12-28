import 'dart:typed_data';
import 'dart:io';
import 'darwin/platform_ocr_darwin.dart';

abstract class PlatformOcr {
  factory PlatformOcr() {
    if (Platform.isMacOS || Platform.isIOS) {
      return DarwinPlatformOcr();
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  Future<String> recognizeText(OcrSource source);
}

abstract class OcrSource {
  factory OcrSource.file(File file) = FileOcrSource;
  factory OcrSource.memory(Uint8List bytes) = MemoryOcrSource;
}

class FileOcrSource implements OcrSource {
  final File file;
  FileOcrSource(this.file);
}

class MemoryOcrSource implements OcrSource {
  final Uint8List bytes;
  MemoryOcrSource(this.bytes);
}
