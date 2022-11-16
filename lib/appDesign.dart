import 'package:flutter/material.dart';

class AppColors {
  static const scaffoldBackgroundColor = Color(0xFFE5E5E5);
  static const pageHeadingColor = Color(0xFFFCFCFC);
  static const h1Color = Color(0xFFFCFCFC);
  static const h2Color = Color(0xFFFCFCFC);
  static const h3Color = Color(0xFFFCFCFC);
  static const h4Color = Color(0xFFFCFCFC);
  static const captionColor = Color(0xFFFCFCFC);
  static const dropdownBackgroundColor = Color(0xFFFCFCFC);
  static const dropdownChoiceColor = Color(0xFF69696B);
  static const dropdownListColor = Color(0xFF262626);
  static const textEntryHeaderColor = Color(0xFFFCFCFC);
  static const textEntryBoxColor = Color(0xFFFCFCFC);
}

class AppTheme {
  static var appTheme = ThemeData(
    brightness: Brightness.dark,
    backgroundColor: AppColors.scaffoldBackgroundColor,
    //primaryColor: Colors.deepOrange[500],
    //secondaryHeaderColor: Colors.blue[800],
    textTheme: TextTheme(
      headline1: TextStyle(
          color: AppColors.h2Color,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter'),
      headline2: TextStyle(
          color: AppColors.h2Color,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter'),
      headline3: TextStyle(
          color: AppColors.h3Color,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter'),
      headline4: TextStyle(
          color: AppColors.h4Color,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat'),
      caption: TextStyle(
          color: AppColors.captionColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat'),
    ),
  );
}
