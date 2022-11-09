import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_bass/flutter_bass.dart';
import 'package:flutter_bass/ffi/generated_bindings.dart';
import 'groove.dart';

final HfAudio hfaudio = new HfAudio();

// Mapping from note name to ogg voice number
var oggMap = <String, num>{
  'none': -1,
  '-': -1,
  'Bass drum': 0,
  'Bass echo': 1,
  'Lo tom': 11,
  'Hi tom': 12,
  'Snare drum': 2,
  'Hi-hat cymbal': 3,
  'Cowbell': 4,
  'Tambourine': 5,
  'Fingersnap': 7,
  'Rim shot': 8,
  'Shaker': 9,
  'Woodblock': 10,
  'Brushes': 13,
  'Quijada': 14,
};

// Mapping from note name to single character reference.  Note
// that this can't be done by simply grabbing the first character since
// there are two notes starting with 'S'.
var initialMap = <String, String>{
  'none': '-',
  '-': '-',
  'Bass drum': 'b',
  'Bass echo': 'B',
  'Snare drum': 'S',
  'Hi-hat cymbal': 'H',
  'Cowbell': 'C',
  'Tambourine': 'M',
  'Fingersnap': 'F',
  'Rim shot': 'R',
  'Shaker': 'A',
  'Woodblock': 'W',
  'Lo tom': 't',
  'Hi tom': 'T',
  'Brushes': 'U',
  'Quijada': 'Q',
};

class HfAudio {
  // flags used to indicate if the persussion or bass sounds have been loaded.
  bool engineInitialized = false;
  bool percussionLoaded = false;
  bool bassLoaded = false;
  int errorCode = 0;
  final infoPointer = calloc<BASS_INFO>();
  int cowbellSample = 0;
  int cowbellChannel = 0;

  void init() {
    // set non-stop mode to reduce playback latency
    bass.BASS_SetConfig(BASS_CONFIG_DEV_NONSTOP, 1);

    // set the device update period to 5ms
    bass.BASS_SetConfig(BASS_CONFIG_DEV_PERIOD, 5);

    // set the device buffer length on Android
    if (Platform.isAndroid) {
      bass.BASS_SetConfig(BASS_CONFIG_DEV_BUFFER, 10);
    }

    // set the update period to 5ms
    bass.BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 5);

    // set the buffer length to 12ms
    bass.BASS_SetConfig(BASS_CONFIG_BUFFER, 12);

    // BASS_Init: -1 = default device, 44100 or 48000 = sample rate, 0 = flags
    if (Platform.isAndroid) {
      bass.BASS_Init(-1, 48000, 0, ffi.nullptr, ffi.nullptr);
    } else if (Platform.isIOS) {
      bass.BASS_Init(-1, 44100, 0, ffi.nullptr, ffi.nullptr);
    }

    errorCode = bass.BASS_ErrorGetCode();
    if (kDebugMode) {
      print('Error code = $errorCode');
    }

    if (groove.type == GrooveType.percussion) {
      if (!this.percussionLoaded) {
        Get.snackbar('Status'.tr, 'Loading percussion sounds.'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
            showProgressIndicator: true);
        initPercussion();
        this.percussionLoaded = true;
      }
    } else if (groove.type == GrooveType.bass) {
      if (!this.bassLoaded) {
        Get.snackbar('Status'.tr, 'Loading bass sounds.'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 10),
            showProgressIndicator: true);
        initBass();
        this.bassLoaded = true;
      }
    } else {
      initPercussion();
    }
  }

  // initialize audio engine for percussion sounds
  void initPercussion() async {
    if (kDebugMode) {
      print('HF: loading percussion files');
    }

    String fileName = await getAudioFileFromAssets('cowbell.mp3');
    if (kDebugMode) {
      print('Loading file: $fileName');
    }
    cowbellSample = bass.BASS_SampleLoad(
        0, // mem: use file instead of memory
        fileName.toNativeUtf8().cast(), // *file: file name pointer
        0, // offset: use file from the start
        0, // length: use entire file
        1, // max: max number of playbacks
        0 // flags: no flags set
        );
    errorCode = bass.BASS_ErrorGetCode();
    if (kDebugMode) {
      print('BASS_SampleLoad complete!: cowbellSample = $cowbellSample, error code = $errorCode');
    }

    cowbellChannel = bass.BASS_SampleGetChannel(cowbellSample, 0);
    if (kDebugMode) {
      print('BASS channel: $cowbellChannel');
    }

    // set the playback buffering length to 0s to minimize latency
    bass.BASS_ChannelSetAttribute(cowbellChannel, BASS_ATTRIB_BUFFER, 0.0);
  }

  // initialize audio engine for bass sounds
  void initBass() async {
    if (kDebugMode) {
      print('HF: loading bass files');
    }
  }

  play(int voices, int note1, int transpose1, int note2, int transpose2) {
    int result = bass.BASS_ChannelPlay(cowbellChannel, 1);
    errorCode = bass.BASS_ErrorGetCode();
    if (kDebugMode) {
      print('Playing sample.  Result = $result, error code = $errorCode');
    }
    if (kDebugMode) {
      // print out some elements of the BASS_INFO struct
      bass.BASS_GetInfo(infoPointer);
      int latency = infoPointer.ref.latency;
      int freq = infoPointer.ref.freq;
      int minBuf = infoPointer.ref.minbuf;
      print('Latency = $latency');
      print('Minbuf = $minBuf');
      print('Frequency = $freq');
    }
  }

  // read an audio file from assets and save to a temporary file
  // This is necessary since files in the root bundle are
  // not accessible as normal files.
  Future<String> getAudioFileFromAssets(String name) async {
    // load from the bundle
    final byteData = await rootBundle.load('assets/sounds/$name');
    final buffer = byteData.buffer;

    // build a temporary file name
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath = tempPath + '/' + name;
    if (kDebugMode) {
      print('Writing to temporary file $filePath');
    }

    // write the data to the temporary file
    File tempFile = await File(filePath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    var length = await tempFile.length();
    if (kDebugMode) {
      print('Wrote temporary file $filePath, length = $length');
    }

    // return the path to the temp file
    return filePath;
  }

  // stop previous note.  This is only used in bass mode since
  // bass notes should not overlap in time.
  // Note this only works in iOS.
  void stop() {
    if (Platform.isAndroid) {
    } else if (Platform.isIOS) {
    }
  }

  void depose() {
    if (Platform.isAndroid) {
    } else if (Platform.isIOS) {
    }
  }
}
