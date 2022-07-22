import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'groove.dart';

GrooveStorage grooveStorage = new GrooveStorage();

class GrooveStorage {
  List directoryContents = [];
  List grooveFileNames = [];

  Future<String> get _localPath async {
    /*
    Directory? directory = Platform.isAndroid
        ? await getExternalStorageDirectory() //FOR ANDROID
        : await getApplicationSupportDirectory(); //FOR iOS
    print('HF: application documents directory : $directory');
    return directory!.path;
    */
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  // get list of .csv files in the applications doc directory
  Future<List> listOfSavedGrooves() async {
    String dir = await _localPath;
    if (kDebugMode) {
      print('HF: application documents directory = $dir');
    }
//    List<FileSystemEntity> files = Directory(dir).listSync(recursive: false);
    final List<FileSystemEntity> entities =
        await Directory(dir).list().toList();
    final Iterable<File> files = entities.whereType<File>();
    this.grooveFileNames = [];
    for (var file in files) {
      if (file.path.contains('.csv')) {
        var grooveName = file.path.replaceAll(dir, '');
        grooveName = grooveName.replaceAll('/', '');
        grooveName = grooveName.replaceAll('.csv', '');
        if (kDebugMode) {
          print('HF: found saved groove $grooveName');
        }
        this.grooveFileNames.add(grooveName);
      }
    }
    var len = this.grooveFileNames.length;
    if (kDebugMode) {
      print('HF: listOfSavedGrooves: found $len saved grooves');
    }
    return this.grooveFileNames;
  }

  Future<void> readGroove(String filename) async {
    final path = await _localPath;
    String fileNameAndPath = path + '/' + filename + '.csv';
    if (kDebugMode) {
      print('HF: reading groove from file $fileNameAndPath');
    }

    File file = File(fileNameAndPath);
    try {
      // Read the file
      final contents = await file.readAsString();
      if (kDebugMode) {
        print('HF: reading from file $filename= $contents');
      }

      // parse the file and populate the groove
      groove.fromCSV(contents);

      return;
    } catch (e) {
      // If encountering an error, return 0
      if (kDebugMode) {
        print('HF: readGroove readAsString error: $e');
      }
      return;
    }
  }

  Future<void> writeGroove(String filename, String description) async {
    final path = await _localPath;
    String fileNameAndPath = path + '/' + filename + '.csv';
    String message = 'Groove written to file ' + filename + '.csv';
    if (kDebugMode) {
      print('HF: writing groove to file $fileNameAndPath');
    }

    File file = File(fileNameAndPath);

    // convert the currently defined groove to a string
    String grooveString = groove.toCSV(description);

    if (kDebugMode) {
      print('HF: writing groove to file as CSV text: $grooveString');
    }

    // Write the file
    try {
      file.writeAsString('$grooveString');
      Get.snackbar('Write status', message,
          snackPosition: SnackPosition.BOTTOM);
      return;
    } catch (e) {
      if (kDebugMode) {
        print('HF: writeGroove writeAsString error: $e');
      }
    }
  }
}
