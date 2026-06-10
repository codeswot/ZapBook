import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FilePickerService {
  Future<File?> pickBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      return File(path);
    }
    return null;
  }

  Future<Uint8List?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) {
      return await File(path).readAsBytes();
    }
    return null;
  }
}
