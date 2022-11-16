import 'package:flutter/material.dart';

class HfMenuItem {
  final String text;
  final Color? color;

  HfMenuItem({
    required this.text,
    required this.color,
  });
}

Widget addVerticalSpace(double height) {
  return SizedBox(height: height);
}

Widget addHorizontalSpace(double width) {
  return SizedBox(width: width);
}
