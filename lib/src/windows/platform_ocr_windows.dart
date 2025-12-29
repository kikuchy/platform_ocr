import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;
import '../platform_ocr_interface.dart';
import 'bindings.g.dart';

class WindowsPlatformOcr implements PlatformOcr {
  OcrEngineHandle? _engine;

  WindowsPlatformOcr() {
    _engine = CreateOcrEngine();
    if (_engine == null || _engine!.address == 0) {
      // Fallback or handle error
      print('Warning: Failed to create Windows OCR engine.');
    }
  }

  @override
  Future<OcrResult> recognizeText(OcrSource source) async {
    final engine = _engine;
    if (engine == null || engine.address == 0) {
      throw Exception('Windows OCR engine not initialized.');
    }

    if (source is FileOcrSource) {
      final bytes = await source.file.readAsBytes();
      return _recognizeFromMemory(bytes);
    } else if (source is MemoryOcrSource) {
      return _recognizeFromMemory(source.bytes);
    }

    throw UnimplementedError('Unsupported source type');
  }

  Future<OcrResult> _recognizeFromMemory(List<int> bytes) async {
    final Uint8List uint8Bytes = Uint8List.fromList(bytes);
    final image = img.decodeImage(uint8Bytes);
    if (image == null) {
      throw Exception('Failed to decode image.');
    }

    final rgbaImage = image.numChannels == 4 && image.bitsPerChannel == 8
        ? image
        : image.convert(format: img.Format.uint8, numChannels: 4);

    final width = rgbaImage.width;
    final height = rgbaImage.height;
    final rgbaBytes = rgbaImage.toUint8List();

    return await using((arena) async {
      final ptr = arena.allocate<ffi.Uint8>(rgbaBytes.length);
      ptr.asTypedList(rgbaBytes.length).setAll(0, rgbaBytes);

      final resultPtr = RecognizeTextFromMemory(_engine!, ptr, width, height);
      if (resultPtr.address == 0) return OcrResult(text: '', lines: []);

      try {
        final jsonStr = resultPtr.cast<Utf16>().toDartString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);

        final String fullText = data['text'] ?? '';
        final List<dynamic> linesData = data['lines'] ?? [];

        final lines = linesData.map((l) {
          final box = Rect.fromLTWH(
            (l['x'] as num).toDouble(),
            (l['y'] as num).toDouble(),
            (l['width'] as num).toDouble(),
            (l['height'] as num).toDouble(),
          );
          return OcrLine(text: l['text'] ?? '', boundingBox: box);
        }).toList();

        return OcrResult(text: fullText, lines: lines);
      } finally {
        FreeOcrResult(resultPtr);
      }
    });
  }

  @override
  void dispose() {
    if (_engine != null && _engine!.address != 0) {
      FreeOcrEngine(_engine!);
      _engine = null;
    }
  }
}
