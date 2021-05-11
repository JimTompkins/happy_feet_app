import 'dart:ffi'; // For FFI
import 'dart:io'; // For Platform.isX

final DynamicLibrary bassLib = Platform.isAndroid
    ? DynamicLibrary.open("libbass.so")
    : DynamicLibrary.process();

final DynamicLibrary midiLib = Platform.isAndroid
    ? DynamicLibrary.open("libbassmidi.so")
    : DynamicLibrary.process();