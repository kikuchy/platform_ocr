import 'package:platform_ocr/platform_ocr.dart';
import 'dart:io';

void main() async {
  final ocr = PlatformOcr();
  final imageFile = File('example/flutter_logo.png');

  if (!await imageFile.exists()) {
    print('Error: example/flutter_logo.png not found.');
    return;
  }

  print('Recognizing text from: ${imageFile.path}...');
  final text = await ocr.recognizeText(OcrSource.file(imageFile));

  print('\n--- RECOGNIZED TEXT ---');
  print(text);
  print('-----------------------');
}
