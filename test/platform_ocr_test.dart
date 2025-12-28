import 'package:test/test.dart';
import 'package:platform_ocr/platform_ocr.dart';

void main() {
  test('PlatformOcr can be initialized', () {
    final ocr = PlatformOcr();
    expect(ocr, isNotNull);
  });
}
