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

class Sample {
  String sampleName = '';
  String initial = '';
  String fileName = '';
  String tempFileName = '';
  int sampleNumber = -1;
  int bassSampleNumber = 0;
  int channelNumber = 0;
  int errorCode = 0;
  final infoPointer = calloc<BASS_INFO>();

  // constructor from number, name, initial, filename
  Sample(int num, String name, String initial, String file) {
    this.sampleNumber = num;
    this.sampleName = name;
    this.initial = initial;
    this.fileName = file;
  }

  // load an audio sample using BASS with these steps:
  //   - calls getAudioFileFromAssets
  //   - loads the newly created temp file into BASS as a sample
  //   - gets a BASS channel to play the sample
  //   - sets the playback buffer length to 0 to minimize latency
  load() async {
    String _fileName = await getAudioFileFromAssets(this.fileName);
    this.tempFileName = _fileName;
    if (kDebugMode) {
      print('HF: load: Loading file: $_fileName');
    }

    this.bassSampleNumber = bass.BASS_SampleLoad(
        0, // mem: use file instead of memory
        _fileName.toNativeUtf8().cast(), // *file: file name pointer
        0, // offset: use file from the start
        0, // length: use entire file
        1, // max: max number of playbacks
        0 // flags: no flags set
        );
    this.errorCode = bass.BASS_ErrorGetCode();
    if (kDebugMode) {
      print(
          'BASS_SampleLoad complete!: BASS sample = ${this.bassSampleNumber}, error code = ${this.errorCode}');
    }

    this.channelNumber = bass.BASS_SampleGetChannel(this.bassSampleNumber, 0);
    if (kDebugMode) {
      print('BASS channel: ${this.channelNumber}');
    }

    // set the playback buffering length to 0s to minimize latency
    bass.BASS_ChannelSetAttribute(this.channelNumber, BASS_ATTRIB_BUFFER, 0.0);

    return;
  }

  // play this sample
  play() {
    assert(this.channelNumber != 0, 'Error: channel number is 0');
    int _result = bass.BASS_ChannelPlay(this.channelNumber, 1);
    assert(_result == 1, 'Error: play result is $_result');
    this.errorCode = bass.BASS_ErrorGetCode();
    assert(this.errorCode == 0, 'Error: error code is $this.errorCode');
    if (kDebugMode) {
      // print out some elements of the BASS_INFO struct
      bass.BASS_GetInfo(infoPointer);
      int latency = infoPointer.ref.latency;
      int freq = infoPointer.ref.freq;
      int minBuf = infoPointer.ref.minbuf;
      print('HF: Latency = $latency, Minbuf = $minBuf, Frequency = $freq');
    }
  }

  // stop this sample.  Note we're actually using the
  // BASS_ChannelPause function here instead of ChannelStop because it
  // was giving errors.  ChannelPause will give a BASS_ERROR_NOPLAY if
  // the channel had already stopped playing.
  stop() {
    assert(this.channelNumber != 0, 'Error: channel number is 0');
    int _result = bass.BASS_ChannelPause(this.channelNumber);
    //assert(_result == 1, 'Error: stop result is $_result');
    this.errorCode = bass.BASS_ErrorGetCode();
    //assert(this.errorCode == 0, 'Error: error code is ${this.errorCode}');
    if (kDebugMode) {
      print(
          'HF: stop: result = $_result, error code = ${this.errorCode}, channel = ${this.channelNumber}');
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
}

var samples = List<Sample>.filled(100, Sample(-1, '-', '', ''));

// Mapping from note name to single character reference.  Note
// that this can't be done by grabbing the first character since
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

class HfAudio {
  // flags used to indicate if the persussion or bass sounds have been loaded.
  bool engineInitialized = false;
  bool percussionLoaded = false;
  bool bassLoaded = false;
  int errorCode = 0;
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

    var _startTime = DateTime.now(); // get system time

    // set up list of percussion sound samples
    samples[0] = Sample(0, 'Bass drum', 'b', 'fatkick.mp3');
    samples[1] = Sample(1, 'Bass echo', 'B', 'kick_drum2.mp3');
    samples[2] = Sample(2, 'Snare drum', 'S', 'snare_drum.mp3');
    samples[3] = Sample(3, 'Hi-hat cymbal', 'H', 'high_hat.mp3');
    samples[4] = Sample(4, 'Cowbell', 'C', 'cowbell.mp3');
    samples[5] = Sample(5, 'Tambourine', 'M', 'tambourine.mp3');
    samples[7] = Sample(7, 'Fingersnap', 'F', 'fingersnap.mp3');
    samples[8] = Sample(8, 'Rim shot', 'R', 'sidestick.mp3');
    samples[9] = Sample(9, 'Shaker', 'A', 'shaker.mp3');
    samples[10] = Sample(10, 'Woodblock', 'W', 'woodblock2.mp3');
    samples[11] = Sample(11, 'Lo tom', 't', 'lodrytom.mp3');
    samples[12] = Sample(12, 'Hi tom', 'T', 'hidrytom.mp3');
    samples[13] = Sample(13, 'Brushes', 'U', 'circlebrush.mp3');
    samples[14] = Sample(14, 'Quijada', 'Q', 'vibraslap.mp3');

    // load the samples
    await samples[0].load();
    await samples[1].load();
    await samples[2].load();
    await samples[3].load();
    await samples[4].load();
    await samples[5].load();
    await samples[7].load();
    await samples[8].load();
    await samples[9].load();
    await samples[10].load();
    await samples[11].load();
    await samples[12].load();
    await samples[13].load();
    await samples[14].load();

    var _finishTime = DateTime.now(); // get system time
    Duration _loadTime = _finishTime.difference(_startTime);
    var _loadTimeMs =
        _loadTime.inMilliseconds.toDouble(); // convert load time to ms

    if (kDebugMode) {
      print('HF: initPercussion: time = $_loadTimeMs ms');
    }
  }

  // initialize audio engine for bass sounds
  void initBass() async {
    if (kDebugMode) {
      print('HF: loading bass files');
    }

    var _startTime = DateTime.now(); // get system time

    samples[40] = Sample(40, 'E1', 'E', '00.mp3');
    samples[41] = Sample(41, 'F1', 'F', '01.mp3');
    samples[42] = Sample(42, 'F#1', 'F', '02.mp3');
    samples[43] = Sample(43, 'G1', 'G', '03.mp3');
    samples[44] = Sample(44, 'G#1', 'G', '04.mp3');
    samples[45] = Sample(45, 'A1', 'A', '05.mp3');
    samples[46] = Sample(46, 'A#1', 'A', '06.mp3');
    samples[47] = Sample(47, 'B1', 'B', '07.mp3');
    samples[48] = Sample(48, 'C2', 'C', '08.mp3');
    samples[49] = Sample(49, 'C#2', 'C', '09.mp3');
    samples[50] = Sample(50, 'D2', 'D', '10.mp3');
    samples[51] = Sample(51, 'D#2', 'D', '11.mp3');
    samples[52] = Sample(52, 'E2', 'E', '12.mp3');
    samples[53] = Sample(53, 'F2', 'F', '13.mp3');
    samples[54] = Sample(54, 'F#2', 'F', '14.mp3');
    samples[55] = Sample(55, 'G2', 'G', '15.mp3');
    samples[56] = Sample(56, 'G#2', 'G', '16.mp3');
    samples[57] = Sample(57, 'A2', 'A', '17.mp3');
    samples[58] = Sample(58, 'A#2', 'A', '18.mp3');
    samples[59] = Sample(59, 'B2', 'B', '19.mp3');
    samples[60] = Sample(60, 'C3', 'C', '20.mp3');
    samples[61] = Sample(61, 'C#3', 'C', '21.mp3');
    samples[62] = Sample(62, 'D3', 'D', '22.mp3');
    samples[63] = Sample(63, 'D#3', 'D', '23.mp3');

    // load the samples
    await samples[40].load();
    await samples[41].load();
    await samples[42].load();
    await samples[43].load();
    await samples[44].load();
    await samples[45].load();
    await samples[46].load();
    await samples[47].load();
    await samples[48].load();
    await samples[49].load();
    await samples[50].load();
    await samples[51].load();
    await samples[52].load();
    await samples[53].load();
    await samples[54].load();
    await samples[55].load();
    await samples[56].load();
    await samples[57].load();
    await samples[58].load();
    await samples[59].load();
    await samples[60].load();
    await samples[61].load();
    await samples[62].load();

    var _finishTime = DateTime.now(); // get system time
    Duration _loadTime = _finishTime.difference(_startTime);
    var _loadTimeMs =
        _loadTime.inMilliseconds.toDouble(); // convert load time to ms

    if (kDebugMode) {
      print('HF: initBass: time = $_loadTimeMs ms');
    }
  }

  play(int note1, int note2) {
    if (note1 != -1) {
      samples[note1].play();
    }
    if (note2 != -1) {
      samples[note2].play();
    }
  }

  // stop previous note.  This is only used in bass mode since
  // bass notes should not overlap in time.
  void stop(int lastNote) {
    samples[lastNote].stop();
    if (kDebugMode) {
      print('HF: stopping last note $lastNote');
    }
  }

  void depose() {
    if (Platform.isAndroid) {
    } else if (Platform.isIOS) {}
  }
}
