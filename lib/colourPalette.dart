import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';

// colour palette from paletton.com
const int shade0 = 0xAA5939;
const int shade1 = 0xFF4900;
const int shade2 = 0xFC4C06;
const int shade3 = 0x584239;
const int shade4 = 0x060606;

// create red, green, blue from shade1 value
const int r = shade1 >> 16 & 0xFF;
const int g = shade1 >> 8 & 0xFF;
const int b = shade1 & 0xFF;
// create RGB + luminence from shade1
const int c1 = shade1 | (0xFF << 24);

Map<int, Color> color =
{
  50:Color.fromRGBO(r, g, b, 0.1),
  100:Color.fromRGBO(r, g, b, 0.2),
  200:Color.fromRGBO(r, g, b, 0.3),
  300:Color.fromRGBO(r, g, b, 0.4),
  400:Color.fromRGBO(r, g, b, 0.5),
  500:Color.fromRGBO(r, g, b, 0.6),
  600:Color.fromRGBO(r, g, b, 0.7),
  700:Color.fromRGBO(r, g, b, 0.8),
  800:Color.fromRGBO(r, g, b, 0.9),
  900:Color.fromRGBO(r, g, b, 1.0),
};

MaterialColor myColour = MaterialColor(c1, color);

