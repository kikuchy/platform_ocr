import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:hooks/hooks.dart';
import 'dart:io';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: (Platform.isMacOS || Platform.isIOS)
          ? 'src/darwin/bindings.g.dart'
          : (Platform.isWindows)
              ? 'src/windows/bindings.g.dart'
              : null,
      sources: [
        if (Platform.isMacOS || Platform.isIOS) 'src/darwin/bindings.g.m',
        if (Platform.isWindows) 'src/windows/ocr_cabi.cpp',
      ],
      includes: [
        if (Platform.isMacOS || Platform.isIOS) 'src/darwin',
        if (Platform.isWindows) 'src/windows',
      ],
      frameworks: [
        if (Platform.isMacOS || Platform.isIOS) 'Vision',
        if (Platform.isMacOS || Platform.isIOS) 'Foundation',
      ],
      libraries: [
        if (Platform.isWindows) 'windowsapp',
      ],
      flags: [
        if (Platform.isMacOS || Platform.isIOS) '-fobjc-arc',
        if (Platform.isWindows) '/std:c++17',
        if (Platform.isWindows) '/EHsc',
      ],
    );
    await cbuilder.run(
      input: input,
      output: output,
    );
  });
}
