import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> fromAsset(String asset, String filename) async {
  try {
    var data = await rootBundle.load(asset);
    var bytes = data.buffer.asUint8List();
    var dir = await getApplicationDocumentsDirectory();
    File file = File("${dir.path}/$filename");

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (e) {
    throw Exception("Error opening asset file: $e");
  }
}
