#ifndef PLATFORM_OCR_WINDOWS_OCR_CABI_H_
#define PLATFORM_OCR_WINDOWS_OCR_CABI_H_

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define OCR_EXPORT __declspec(dllexport)
#else
#define OCR_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// OCR Engine Handle
typedef void *OcrEngineHandle;

// Initialize OCR engine with default language
OCR_EXPORT OcrEngineHandle CreateOcrEngine();

// Free OCR engine
OCR_EXPORT void FreeOcrEngine(OcrEngineHandle handle);

// Recognize text from image bytes (RGBA)
// Returns a semicolon-separated string of recognized text.
// Caller must free the returned string with FreeOcrResult.
OCR_EXPORT const wchar_t *RecognizeTextFromMemory(OcrEngineHandle handle,
                                                  const uint8_t *imageBytes,
                                                  uint32_t width,
                                                  uint32_t height);

// Free recognized text string
OCR_EXPORT void FreeOcrResult(const wchar_t *result);

#ifdef __cplusplus
}
#endif

#endif // PLATFORM_OCR_WINDOWS_OCR_CABI_H_
