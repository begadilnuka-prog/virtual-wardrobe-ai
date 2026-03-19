import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalImageStorageService {
  Future<String> persistImage({
    required String scope,
    required String userId,
    required String entryId,
    required String sourcePath,
  }) async {
    if (sourcePath.isEmpty || sourcePath.startsWith('http')) {
      return sourcePath;
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return sourcePath;
    }

    final directory = await getApplicationDocumentsDirectory();
    final targetDirectory = Directory('${directory.path}/$scope/$userId');
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final extension = sourcePath.contains('.')
        ? sourcePath.split('.').last.toLowerCase()
        : 'jpg';
    final destination = File('${targetDirectory.path}/$entryId.$extension');

    if (sourceFile.path == destination.path) {
      return destination.path;
    }

    await sourceFile.copy(destination.path);
    return destination.path;
  }

  Future<void> deleteIfOwned(String imagePath) async {
    if (imagePath.isEmpty || imagePath.startsWith('http')) {
      return;
    }

    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
