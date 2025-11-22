// Implementation for non-web platforms using dart:io
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(String content, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
}

