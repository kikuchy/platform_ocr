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
  Future<String> recognizeText(OcrSource source) async {
    return await pkg_ffi.using((arena) async {
      String result = '';
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

        // handler.performRequests:error:
        // package:objective_c generated methods throw NSErrorException on failure.
        final success = handler.performRequests(requests);
        if (!success) {
          throw Exception('Vision request failed without error details');
        }

        final results = request.results;
        if (results != null) {
          final sb = StringBuffer();
          for (int i = 0; i < results.count; i++) {
            final obj = results.objectAtIndex(i);
            if (VNRecognizedTextObservation.isA(obj)) {
              final observation = VNRecognizedTextObservation.as(obj);
              final topCandidates = observation.topCandidates(1);
              if (topCandidates.count > 0) {
                final text =
                    VNRecognizedText.as(topCandidates.objectAtIndex(0));
                sb.writeln(text.string.toDartString());
              }
            }
          }
          result = sb.toString().trim();
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
