import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnalysisLoadingWidget extends StatelessWidget {
  const AnalysisLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Spacer(),
          Lottie.asset("assets/lottie/racquet-loading.json"),
          const SizedBox(height: 30),
          const Text(
            "Analyzing Serve",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
