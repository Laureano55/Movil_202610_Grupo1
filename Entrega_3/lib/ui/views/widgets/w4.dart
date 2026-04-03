import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/count_controller.dart';

class W4 extends StatelessWidget {
  const W4({super.key});

  @override
  Widget build(BuildContext context) {
    CountController countController = Get.find();
    return Container(
      color: Colors.blueGrey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            key: Key('decrementButton'),
            onPressed: () => countController.decrement(),
            child: Text('Decrease'),
          ),
        ],
      ),
    );
  }
}
