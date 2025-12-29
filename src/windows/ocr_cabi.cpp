#include "ocr_cabi.h"
#include <string>
#include <vector>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>

using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::Media::Ocr;
using namespace Windows::Graphics::Imaging;
using namespace Windows::Storage::Streams;

struct OcrContext {
  OcrEngine engine{nullptr};
};

OcrEngineHandle CreateOcrEngine() {
  try {
    auto engine = OcrEngine::TryCreateFromUserProfileLanguages();
    if (engine == nullptr)
      return nullptr;

    return reinterpret_cast<OcrEngineHandle>(new OcrContext{std::move(engine)});
  } catch (...) {
    return nullptr;
  }
}

void FreeOcrEngine(OcrEngineHandle handle) {
  if (handle) {
    delete reinterpret_cast<OcrContext *>(handle);
  }
}

const wchar_t *RecognizeTextFromMemory(OcrEngineHandle handle,
                                       const uint8_t *imageBytes,
                                       uint32_t width, uint32_t height) {

  if (!handle)
    return nullptr;
  auto context = reinterpret_cast<OcrContext *>(handle);

  try {
    // Create a SoftwareBitmap from RGBA bytes
    // Note: C++/WinRT SoftwareBitmap expects a buffer
    DataWriter writer;
    writer.WriteBytes(
        std::vector<uint8_t>(imageBytes, imageBytes + (width * height * 4)));
    auto buffer = writer.DetachBuffer();

    SoftwareBitmap bitmap(BitmapPixelFormat::Rgba8, width, height,
                          BitmapAlphaMode::Premultiplied);
    bitmap.CopyFromBuffer(buffer);

    // Recognize
    auto result = context->engine.RecognizeAsync(bitmap).get();

    std::wstring output;
    for (auto &&line : result.Lines()) {
      output += line.Text();
      output += L"\n";
    }

    if (output.empty())
      return nullptr;

    // Allocate memory for the result string to be returned to Dart
    size_t size = (output.length() + 1) * sizeof(wchar_t);
    wchar_t *resultStr = static_cast<wchar_t *>(malloc(size));
    if (resultStr) {
      wcscpy_s(resultStr, output.length() + 1, output.c_str());
    }
    return resultStr;
  } catch (...) {
    return nullptr;
  }
}

void FreeOcrResult(const wchar_t *result) {
  if (result) {
    free(const_cast<wchar_t *>(result));
  }
}
