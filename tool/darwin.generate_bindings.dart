// Regenerate bindings with `dart run tools/darwin.generate_bindings.dart`.
import 'dart:io';
import 'package:ffigen/ffigen.dart';

String get macSdkPath {
  final result = Process.runSync('xcrun', [
    '--show-sdk-path',
    '--sdk',
    'macosx',
  ]);
  if (result.exitCode != 0) {
    throw Exception('Failed to get macOS SDK path: ${result.stderr}');
  }
  return result.stdout.toString().trim();
}

final config = FfiGenerator(
  headers: Headers(
    entryPoints: [
      Uri.file(
        '$macSdkPath/System/Library/Frameworks/Vision.framework/Headers/Vision.h',
      ),
    ],
    compilerOptions: [
      '-Dsimd_float4x4=int',
      '-Dsimd_float4=int',
      '-Dmatrix_float3x3=int',
      '-Dsimd_float3=int',
      '-Dsimd_float2=int',
    ],
  ),
  objectiveC: ObjectiveC(
    interfaces: Interfaces(
      include: (decl) => {
        'VNImageRequestHandler',
        'VNRecognizeTextRequest',
        'VNRecognizedTextObservation',
        'VNRecognizedText',
        'VNObservation',
        'VNRequest',
        'VNImageBasedRequest',
      }.contains(decl.originalName),
      includeTransitive: false,
    ),
    protocols: Protocols(include: (decl) => false, includeTransitive: false),
  ),
  output: Output(
    dartFile: Uri.file('lib/src/darwin/bindings.g.dart'),
    objectiveCFile: Uri.file('src/darwin/bindings.g.m'),
  ),
  functions: Functions(
    include: (decl) => {
      'VNImageRectForNormalizedRect',
      'CFRelease',
    }.contains(decl.originalName),
  ),
);

void main() => config.generate();
