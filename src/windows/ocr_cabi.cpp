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

std::wstring EscapeJsonString(const std::wstring &input) {
  std::wstring output;
  for (wchar_t c : input) {
    switch (c) {
    case L'\"':
      output += L"\\\"";
      break;
    case L'\\':
      output += L"\\\\";
      break;
    case L'\b':
      output += L"\\b";
      break;
    case L'\f':
      output += L"\\f";
      break;
    case L'\n':
      output += L"\\n";
      break;
    case L'\r':
      output += L"\\r";
      break;
    case L'\t':
      output += L"\\t";
      break;
    default:
      if (c < 32) {
        wchar_t buf[10];
        swprintf_s(buf, L"\\u%04x", c);
        output += buf;
      } else {
        output += c;
      }
    }
  }
  return output;
}

const wchar_t *RecognizeTextFromMemory(OcrEngineHandle handle,
                                       const uint8_t *imageBytes,
                                       uint32_t width, uint32_t height) {

  if (!handle)
    return nullptr;
  auto context = reinterpret_cast<OcrContext *>(handle);

  try {
    DataWriter writer;
    writer.WriteBytes(
        std::vector<uint8_t>(imageBytes, imageBytes + (width * height * 4)));
    auto buffer = writer.DetachBuffer();

    SoftwareBitmap bitmap(BitmapPixelFormat::Rgba8, width, height,
                          BitmapAlphaMode::Premultiplied);
    bitmap.CopyFromBuffer(buffer);

    auto result = context->engine.RecognizeAsync(bitmap).get();

    std::wstring json = L"{";
    json += L"\"text\":\"" + EscapeJsonString(result.Text().c_str()) + L"\",";
    json += L"\"lines\":[";

    bool firstLine = true;
    for (auto &&line : result.Lines()) {
      if (!firstLine)
        json += L",";
      firstLine = false;

      json += L"{";
      json += L"\"text\":\"" + EscapeJsonString(line.Text().c_str()) + L"\",";

      // Calculate bounding box from words
      double minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
      for (auto &&word : line.Words()) {
        auto rect = word.BoundingRect();
        minX = std::min(minX, (double)rect.X);
        minY = std::min(minY, (double)rect.Y);
        maxX = std::max(maxX, (double)rect.X + rect.Width);
        maxY = std::max(maxY, (double)rect.Y + rect.Height);
      }

      json += L"\"x\":" + std::to_wstring(minX) + L",";
      json += L"\"y\":" + std::to_wstring(minY) + L",";
      json += L"\"width\":" + std::to_wstring(maxX - minX) + L",";
      json += L"\"height\":" + std::to_wstring(maxY - minY);
      json += L"}";
    }
    json += L"]}";

    size_t size = (json.length() + 1) * sizeof(wchar_t);
    wchar_t *resultStr = static_cast<wchar_t *>(malloc(size));
    if (resultStr) {
      wcscpy_s(resultStr, json.length() + 1, json.c_str());
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
