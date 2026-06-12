import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/signature_export_result.dart';

class SignatureStorageService {
  Future<File> saveLocally(SignatureExportResult result) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/signature_$timestamp.png');
    return file.writeAsBytes(result.bytes);
  }
}
