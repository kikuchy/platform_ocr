import 'dart:typed_data';
import 'dart:io';
import 'darwin/platform_ocr_darwin.dart';
import 'windows/platform_ocr_windows.dart';

abstract class PlatformOcr {
  factory PlatformOcr() {
    if (Platform.isMacOS || Platform.isIOS) {
      return DarwinPlatformOcr();
    }
    if (Platform.isWindows) {
      return WindowsPlatformOcr();
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  Future<OcrResult> recognizeText(OcrSource source);

  void dispose();
}

class OcrResult {
  final String text;
  final List<OcrLine> lines;

  OcrResult({required this.text, required this.lines});

  @override
  String toString() => text;
}

class OcrLine {
  final String text;
  final Rect boundingBox;

  OcrLine({required this.text, required this.boundingBox});
}

class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect.fromLTWH(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  @override
  String toString() =>
      'Rect.fromLTWH(${left.toStringAsFixed(2)}, ${top.toStringAsFixed(2)}, ${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)})';
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
