import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:get/get.dart';
import '../main.dart';
import '../appDesign.dart';

WalkthroughScreen walkthroughScreen = new WalkthroughScreen();

class WalkthroughScreen extends StatefulWidget {
  @override
  _WalkthroughScreenState createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  @override
  initState() {
    super.initState();
    initPreferences();
  }

  void _onIntroEnd(context) {
    if (kDebugMode) {
      print('HF: leaving the walkthrough');
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyHomePage()),
    );
  }

  void _onSkip(context) {
    if (kDebugMode) {
      print('HF: skipping the walkthrough');
    }
    showWalkthrough = false;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyHomePage()),
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/images/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = const PageDecoration(
      titleTextStyle: AppTheme.walkthroughTitleText,
      bodyTextStyle: AppTheme.walkthroughBodyText,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: AppColors.scaffoldBackgroundColor,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,

      globalHeader: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
          ),
        ),
      ),

      pages: [
        PageViewModel(
          reverse: true,
          title: 'Welcome'.tr,
          body: 'Welcome to HappyFeet!  Thank you for buying HappyFeet.'.tr,
          image: _buildImage('overview.jpg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          reverse: true,
          image: _buildImage('charging.jpg'),
          title: 'Charging'.tr,
          body:
              'Connect the USB cable provided to HappyFeet and to any USB port.  The red light will come on.  When the red light goes out, your HappyFeet is fully charged.'
                  .tr,
          decoration: pageDecoration,
        ),
        PageViewModel(
          reverse: true,
          title: 'Putting on HappyFeet'.tr,
          body:
              'Put HappyFeet on your shoe with the blue light on the right.  Adjust the Velcro strap as you like.'
                  .tr,
          image: _buildImage('shoe.jpg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          reverse: true,
          title: 'Connect to HappyFeet'.tr,
          body:
              'Press the Connect switch to connect to your HappyFeet.  It must be charged and nearby, and Bluetooth must be enabled.'
                  .tr,
          image: _buildImage('connect.jpeg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          reverse: true,
          title: 'Enable beats'.tr,
          body:
              'Press the music note button at the bottom of the screen to enable beat detection.  Press it again to disable beat detection.'
                  .tr,
          image: _buildImage('beats.jpeg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          reverse: true,
          title: 'Choose a sound'.tr,
          body: 'Select a sound using the 1st note pulldown menu.'.tr,
          image: _buildImage('beats.jpeg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          reverse: true,
          title: 'Tap your foot'.tr,
          body:
              'Tap your foot to play the selected sound.  Experiment with other sounds and play modes.  Have fun!'
                  .tr,
          image: _buildImage('beats.jpeg'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onSkip(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back),
      skip: Text('Skip'.tr, style: AppTheme.walkthroughButtonText),
      next:
          const Icon(Icons.arrow_forward, size: 20.0, color: AppColors.h1Color),
      done: Text('Done'.tr, style: AppTheme.walkthroughButtonText),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsFlex: 2, // disables the expanded dots behaviour,
      // added to prevent render overflow
      // see github.com./Pyozer/introduction_screen/issues/7
      dotsDecorator: const DotsDecorator(
        size: Size(8.0, 8.0),
        color: AppColors.h1Color,
        activeSize: Size(8.0, 8.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: AppColors.myButtonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
