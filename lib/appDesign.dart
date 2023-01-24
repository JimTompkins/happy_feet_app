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
  static const settingsIconColor = Color(0xFFD6F3F8);
  static const walkthroughBoxColor = Color(0xFFF4FFFD);
  static const walkthroughButtonColor = Color(0xFF15616D);
  static const walkthroughTextColor = Color(0xFF15616D);
  static const myButtonColor = Color(0xFF15616D);
  static const bottomBarColor = Color(0xFF15616D);
}

class AppTheme {
  static var appTheme = ThemeData(
    appBarTheme: AppBarTheme(
       color: AppColors.bottomBarColor,
    ),
    brightness: Brightness.dark,
    backgroundColor: AppColors.scaffoldBackgroundColor,
    //primaryColor: Colors.deepOrange[500],
    secondaryHeaderColor: AppColors.scaffoldBackgroundColor,
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
          // used for list items after picked
          color: AppColors.dropdownChoiceColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat'),
      caption: TextStyle(
          color: AppColors.captionColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat'),
      labelMedium: TextStyle(
          // used for list items before picked
          color: AppColors.dropdownListColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat'),
    ),
  );
  static const walkthroughText = TextStyle(
    color: AppColors.walkthroughTextColor,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );
  static const walkthroughButtonText = TextStyle(
    color: AppColors.h1Color,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );
  static const walkthroughTitleText = TextStyle(
    color: Color(0xFF15616D),
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );
  static const walkthroughBodyText = TextStyle(
    color: Color(0xFF15616D),
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );
}
