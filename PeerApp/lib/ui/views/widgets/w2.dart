import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/count_controller.dart';

class W2 extends StatelessWidget {
  const W2({super.key});

  @override
  Widget build(BuildContext context) {
    final CountController countController = Get.find();
    return Container(
      color: Colors.deepOrange,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => Text(countController.initial.value)),
          ElevatedButton(
            key: const Key('resetButton'),
            onPressed: () => countController.reset(),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }
}
