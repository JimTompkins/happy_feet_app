import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:get/get.dart';
import '../main.dart';
import '../appDesign.dart';
import '../utils.dart';

WalkthroughScreen walkthroughScreen = new WalkthroughScreen();

class WalkthroughScreen extends StatefulWidget {
  @override
  _WalkthroughScreenState createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

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
      //pageColor: Colors.white,
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
            //child: addVerticalSpace(20),
            //child: _buildImage('flutter.png', 100),
          ),
        ),
      ),

      /*
      globalFooter: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          child: Text(
            'Start using HappyFeet'.tr,
            style: TextStyle(
              fontSize: 16.0, fontWeight: FontWeight.bold,
              color: AppColors.walkthroughTextColor),
          ),
          onPressed: () => _onIntroEnd(context),
        ),
      ),
      */

      pages: [
        PageViewModel(
          reverse: true,
          title: 'Welcome'.tr,
          body: 'Welcome to HappyFeet!  Thank you for buying HappyFeet.'.tr,
          image: _buildImage('Logo_v14.png'),
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
          image: _buildImage('charging.jpg'),
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
      next: const Icon(Icons.arrow_forward,
         size: 40.0,
         color: AppColors.h1Color),
      done: Text('Done'.tr, style: AppTheme.walkthroughButtonText),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(16.0, 16.0),
        color: AppColors.h1Color,
        activeSize: Size(18.0, 18.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
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
