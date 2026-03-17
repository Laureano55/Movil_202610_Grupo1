import 'package:get/get.dart';

class CountController extends GetxController {
  var initial = "0".obs;

  String get value => initial.value;

  void incrementValue() {
    initial.value = (int.parse(initial.value) + 1).toString();
  }

  void decrement() {
    initial.value = (int.parse(initial.value) - 1).toString();
  }

  void reset() {
    initial.value = "0";
  }
}
