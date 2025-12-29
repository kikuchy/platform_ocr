import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:objective_c/objective_c.dart' as objc;
import 'package:ffi/ffi.dart' as pkg_ffi;
import '../platform_ocr_interface.dart';
import 'bindings.g.dart';

class DarwinPlatformOcr implements PlatformOcr {
  DarwinPlatformOcr() {
    if (Platform.isMacOS) {
      ffi.DynamicLibrary.open(
        '/System/Library/Frameworks/Vision.framework/Vision',
      );
    }
    // iOS doesn't need explicit loading or handles it differently,
    // but for macOS CLI it's often necessary.
  }

  @override
  Future<OcrResult> recognizeText(OcrSource source) async {
    return await pkg_ffi.using((arena) async {
      OcrResult result = OcrResult(text: '', lines: []);
      objc.autoReleasePool(() {
        final request = VNRecognizeTextRequest.alloc().init();

        VNImageRequestHandler? handler;
        final options = objc.NSDictionary.new$();

        if (source is FileOcrSource) {
          final url =
              objc.NSURL.fileURLWithPath(objc.NSString(source.file.path));
          handler = VNImageRequestHandler.alloc().initWithURL(
            url,
            options: options,
          );
        } else if (source is MemoryOcrSource) {
          final ptr = arena.allocate<ffi.Uint8>(source.bytes.length);
          ptr.asTypedList(source.bytes.length).setAll(0, source.bytes);
          final data = objc.NSData.dataWithBytes(
            ptr.cast<ffi.Void>(),
            length: source.bytes.length,
          );
          handler = VNImageRequestHandler.alloc().initWithData(
            data,
            options: options,
          );
        }

        if (handler == null) {
          throw UnimplementedError('Unsupported source type');
        }

        final requests = objc.NSArray.arrayWithObject(request);
        final success = handler.performRequests(requests);
        if (!success) {
          throw Exception('Vision request failed');
        }

        final resultsArr = request.results;
        if (resultsArr != null) {
          final lines = <OcrLine>[];
          final fullTextBuffer = StringBuffer();

          for (int i = 0; i < resultsArr.count; i++) {
            final obj = resultsArr.objectAtIndex(i);
            if (VNRecognizedTextObservation.isA(obj)) {
              final observation = VNRecognizedTextObservation.as(obj);
              final topCandidates = observation.topCandidates(1);
              if (topCandidates.count > 0) {
                final recognizedText =
                    VNRecognizedText.as(topCandidates.objectAtIndex(0));
                final text = recognizedText.string.toDartString();

                // Vision boundingBox is normalized [0, 1] with bottom-left origin.
                // Flutter Rect uses top-left origin.
                final box = observation.boundingBox;
                // box.origin.y is bottom-y in Vision.
                // top-y = 1.0 - bottom-y - height
                final rect = Rect.fromLTWH(
                  box.origin.x,
                  1.0 - box.origin.y - box.size.height,
                  box.size.width,
                  box.size.height,
                );

                lines.add(OcrLine(text: text, boundingBox: rect));
                fullTextBuffer.writeln(text);
              }
            }
          }
          result = OcrResult(
            text: fullTextBuffer.toString().trim(),
            lines: lines,
          );
        }
      });
      return result;
    });
  }

  @override
  void dispose() {
    // noop
  }
}
