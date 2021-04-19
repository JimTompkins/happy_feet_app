import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';

class MidiUtils {
  //MidiUtils._();

  final instance = FlutterMidi();

  void play(int midi) => instance.playMidiNote(midi: midi);

  void stop(int midi) => instance.stopMidiNote(midi: midi);

  void unmute() => instance.unmute();

  void prepare(ByteData sf2, String name) =>
      instance.prepare(sf2: sf2, name: "Piano.sf2");
}
