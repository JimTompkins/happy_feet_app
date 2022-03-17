import 'package:get/get.dart';
class MyBool {
  RxBool x = false.obs;

  MyBool(RxBool val) {
    x = val;
  }
}