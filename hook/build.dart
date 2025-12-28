import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final cbuilder = CBuilder.library(
      name: packageName,
      sources: [
        'src/darwin/bindings.g.m',
      ],
      includes: [
        'src/darwin',
      ],
      frameworks: [
        'Vision',
        'Foundation',
      ],
      flags: [
        '-fobjc-arc',
      ],
    );
    await cbuilder.run(
      input: input,
      output: output,
    );
  });
}
