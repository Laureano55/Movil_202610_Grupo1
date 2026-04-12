// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/count_controller.dart';

class W1 extends StatelessWidget {
  const W1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CountController countController = Get.find();

    return Container(
      color: Colors.amber,
      child: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(countController.initial.value),
            ElevatedButton(
              key: const Key('incrementButton'),
              onPressed: countController.incrementValue,
              child: Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
