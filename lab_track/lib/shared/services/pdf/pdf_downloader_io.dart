import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile and Desktop implementation using File I/O and PathProvider.
Future<String?> downloadPdfBytes(List<int> bytes, String fileName) async {
  if (Platform.isAndroid) {
    return await const MethodChannel('labtrack/pdf').invokeMethod<String>(
      'savePdf',
      {'bytes': Uint8List.fromList(bytes), 'fileName': fileName},
    );
  }
  Directory dir;
  try {
    final downloads = await getDownloadsDirectory();
    dir = downloads ?? await getApplicationDocumentsDirectory();
  } catch (_) {
    dir = await getApplicationDocumentsDirectory();
  }

  await dir.create(recursive: true);
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
