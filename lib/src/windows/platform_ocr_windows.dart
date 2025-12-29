import 'dart:ffi' as ffi;
import 'dart:typed_data';
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
  Future<String> recognizeText(OcrSource source) async {
    final engine = _engine;
    if (engine == null || engine.address == 0) {
      throw Exception('Windows OCR engine not initialized.');
    }

    if (source is FileOcrSource) {
      // For Windows, we might want to load the file into memory first
      // since our CABI currently only takes memory.
      final bytes = await source.file.readAsBytes();
      return _recognizeFromMemory(bytes);
    } else if (source is MemoryOcrSource) {
      return _recognizeFromMemory(source.bytes);
    }

    throw UnimplementedError('Unsupported source type');
  }

  Future<String> _recognizeFromMemory(List<int> bytes) async {
    // Decode image to get raw RGBA bytes
    // TODO: Transition to Windows Imaging Component (WIC) for better performance and native compatibility.
    final image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) {
      throw Exception('Failed to decode image.');
    }

    // Ensure image is in RGBA8 format
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
      if (resultPtr.address == 0) return '';

      try {
        // On Windows, resultPtr is Pointer<WChar> (UTF-16)
        return resultPtr.cast<Utf16>().toDartString();
      } finally {
        FreeOcrResult(resultPtr);
      }
    });
  }

  void dispose() {
    if (_engine != null && _engine!.address != 0) {
      FreeOcrEngine(_engine!);
      _engine = null;
    }
  }
}
