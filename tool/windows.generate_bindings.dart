import 'package:ffigen/ffigen.dart';

void main() {
  final config = FfiGenerator(
    headers: Headers(
      entryPoints: [
        Uri.file('src/windows/ocr_cabi.h'),
      ],
    ),
    output: Output(
      dartFile: Uri.file('lib/src/windows/bindings.g.dart'),
    ),
    functions: Functions(
      include: (decl) => true,
    ),
    typedefs: Typedefs(
      include: (decl) => true,
    ),
    globals: Globals(
      include: (decl) => true,
    ),
    structs: Structs(
      include: (decl) => true,
    ),
  );

  config.generate();
  print('Generated lib/src/windows/bindings.g.dart');
}
