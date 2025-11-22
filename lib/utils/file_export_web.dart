// lib/utils/file_export_web.dart
// Web-specific file export functionality

import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadFile(String content, String filename, String mimeType) async {
  final bytes = Uint8List.fromList(content.codeUnits);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
