# 各OS ネイティブ OCR を用いた Dart パッケージ実装計画

## 概要

本パッケージは、**各プラットフォームのネイティブ OCR API を直接利用**し、  
Dart / Flutter から **高速・高精度・ローカル処理可能な文字認識（OCR）** を提供することを目的とする。

初期対応プラットフォームは以下とする。

| プラットフォーム | 使用するネイティブ API |
|------------------|------------------------|
| Windows          | Windows ネイティブ OCR（WinRT） |
| iOS / macOS      | Vision Framework（VNRecognizeTextRequest） |

本計画では、**Windows 実装を基準**として設計し、  
iOS / macOS では同等の API 仕様・振る舞いを目指す。

---

## 設計方針

### 1. ネイティブ API を直接使用する理由

- OS 標準の OCR は
  - ユーザーの言語設定を自動反映
  - OS に最適化されたモデルを利用
  - ネットワーク不要（プライバシー保護）
- サードパーティ OCR エンジン（Tesseract 等）より
  - セットアップが容易
  - モバイル・デスクトップ双方で一貫した品質

---

### 2. Dart からの呼び出し方式

| プラットフォーム | 呼び出し方式 |
|------------------|--------------|
| Windows          | Dart FFI + C ABI DLL |
| iOS / macOS      | Dart FFI + Objective-C / Swift ラッパー |

Dart 側には **共通インターフェース層**を設け、  
プラットフォーム差分はネイティブ実装に閉じ込める。

---

## Windows 実装方針

### 使用 API

- **Windows ネイティブ OCR**
  - `Windows.Media.Ocr::OcrEngine`
  - または将来的に `Windows.AI.Text` への切り替えを検討

### 実装構成

package_root/
├─ src/
│  └─ darwin/            # iOS / macOS 実装
│      └─ bindings.g.m        # ffigenによって生成されたラッパー（あれば）
│  └─ windows/            # Windows 実装
│      ├─ ocr_cabi.h          # C ABI 公開ヘッダ
│      └─ ocr_cabi.cpp        # C++/WinRT 実装
├─ hooks/
│  └─ build.dart          # Dart native assets build hook
├─ lib/
│  ├─ ocr.dart            # 共通 Dart API
│  ├─ android/            # Android 実装
│  ├─ darwin/             # iOS / macOS 実装
│  └─ windows/            # Windows 実装

### 特徴

- C ABI で DLL を公開
- Dart Hooks（native assets）で自動ビルド・同梱
- UTF-16（`wchar_t*`）で文字列を受け渡し
- OCR 処理は完全ローカル

---

## iOS / macOS 実装方針

### 使用 API

- **Vision Framework**
  - `VNRecognizeTextRequest`
  - iOS / macOS 標準の OCR API

### 実装方針

- Objective-C / Swift で薄いラッパーを実装
- C ABI で公開し Dart FFI から呼び出す
- Windows 実装と同等の API シグネチャを維持

---

## Android 実装方針

### 使用 API

- **ML Kit Text Recognition**
  - on-device text recognition
  - Google Play Services 依存（初期ダウンロードあり）

### 実装方針

- JNI + C++ ラッパーを用意
- Dart FFI から C ABI を経由して呼び出す
- Android 依存部分は isolate で非同期処理

---

## 共通 Dart API 設計

利用者が簡単に OCR を実行できるよう、関数一つで完結する API と、インスタンスを使い回す API の両方を提供する。

### 1. 便利関数 (Top-level Function)
ライフサイクル管理（初期化・破棄）を自動で行う方式。

```dart
import 'package:platform_ocr/platform_ocr.dart';

final String text = await recognizeText(OcrSource.file(file));
```

### 2. インスタンス方式
大量の画像を連続して処理する場合、エンジンを再利用して高速化する方式。

```dart
final ocr = PlatformOcr();
for (final file in files) {
  final text = await ocr.recognizeText(OcrSource.file(file));
}
ocr.dispose();
```
```