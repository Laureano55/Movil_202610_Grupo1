import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../viewmodels/count_controller.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    final CountController countController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page 2'),
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Obx(
          () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(countController.value),
              ElevatedButton(
                key: const Key('incrementButtonPage2'),
                onPressed: () => countController.incrementValue(),
                child: Text('Increment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
