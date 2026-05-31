import 'dart:io';

Future<File> writeTempFixture(String fileName, List<int> bytes) async {
  final directory = await Directory.systemTemp.createTemp('zapbook_fixture');
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file;
}

Future<Directory> createTempDirectory() {
  return Directory.systemTemp.createTemp('zapbook_output');
}
