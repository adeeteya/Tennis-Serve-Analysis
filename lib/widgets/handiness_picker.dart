import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_serve_analysis/controllers/user_controller.dart';

class HandinessPicker extends StatelessWidget {
  const HandinessPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Primary hand",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                return SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: ElevatedButton.styleFrom(
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: true,
                      label: const Text('Left'),
                      icon: Transform.rotate(
                        angle: 3 * pi / 2,
                        child: const Icon(Icons.sports_tennis),
                      ),
                    ),
                    const ButtonSegment<bool>(
                      value: false,
                      label: Text('Right'),
                      icon: Icon(Icons.sports_tennis),
                    ),
                  ],
                  selected: <bool>{
                    ref.watch(userServeDataProvider
                        .select((value) => value.isLeftHanded))
                  },
                  onSelectionChanged: (Set<bool> newSelection) {
                    ref
                        .read(userServeDataProvider.notifier)
                        .onHandinessChange(newSelection.first);
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
