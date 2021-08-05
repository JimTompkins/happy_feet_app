import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'groove.dart';

GrooveStorage grooveStorage = new GrooveStorage();

class GrooveStorage {
  List grooveFileNames = [];

  Future<String?> get _localPath async {
    final directory = (await getExternalStorageDirectory())?.path;
    print('HF: application documents directory : $directory');
    return directory;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/groove.csv');
  }

  // get list of .csv files in the applications doc directory
  void listofSavedGrooves() async {
    var directory = (await getExternalStorageDirectory())?.path;
    print('HF: external storage directory = $directory');
    this.grooveFileNames = await Directory("$directory/").listSync();
    var len = this.grooveFileNames.length;
    print('HF: listofSavedGrooves in $directory, $len');
    for (int i = 0; i < len; i++) {
      print('HF:  $i:  $this.grooveFileName[i].name');
    }

  }

  Future<int> readGroove(String filename) async {
    final path = await _localPath;
    String fileNameAndPath = path + '/' + filename + '.csv';
    print('HF: reading groove from file $fileNameAndPath');

    File file = File(fileNameAndPath);
    if (file != null) {
      try {
        // Read the file
        final contents = await file.readAsString();
        print('HF: reading from file $filename= $contents');

        // parse the file and populate the groove
        groove.fromCSV(contents);

        return 0;
      } catch (e) {
        // If encountering an error, return 0
        print('HF: read error: $e');
        return 0;
      }
    }
    else {
      print('HF: read error: file not found');
      return -1;
    }
  }

  Future<File> writeGroove(String filename, String description) async {
    final path = await _localPath;
    String fileNameAndPath = path + '/' + filename + '.csv';
    print('HF: writing groove to file $fileNameAndPath');

    File file = File(fileNameAndPath);

    // convert the currently defined groove to a string
    String grooveString = groove.toCSV(description);

    print('HF: writing groove to file as CSV text: $grooveString');

    // Write the file
    return file.writeAsString('$grooveString');
  }
}
