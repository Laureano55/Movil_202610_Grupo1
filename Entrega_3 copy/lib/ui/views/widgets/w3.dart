import 'package:f_getxstate_demo/ui/viewmodels/count_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class W3 extends StatelessWidget {
  const W3({super.key});

  @override
  Widget build(BuildContext context) {
    CountController countController = Get.find();
    return Container(
      color: Colors.yellowAccent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Obx(() => Text(countController.value))],
      ),
    );
  }
}
