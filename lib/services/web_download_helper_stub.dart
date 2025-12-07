// lib/services/web_download_helper_stub.dart
// Stub for non-web platforms

import 'dart:typed_data';

/// Trigger a file download (stub - not available on this platform)
void downloadFile(String jsonString, String filename) {
  throw UnsupportedError('Web downloads are only available on web platform');
}

/// Trigger a binary file download (stub - not available on this platform)
void downloadBytes(Uint8List bytes, String filename, {String mimeType = 'application/zip'}) {
  throw UnsupportedError('Web downloads are only available on web platform');
}
