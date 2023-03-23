import 'dart:math';

import 'package:flutter/material.dart';

class HandinessPicker extends StatefulWidget {
  final ValueChanged<bool> onChange;
  const HandinessPicker({Key? key, required this.onChange}) : super(key: key);

  @override
  State<HandinessPicker> createState() => _HandinessPickerState();
}

class _HandinessPickerState extends State<HandinessPicker> {
  bool isLeft = false;
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
            SegmentedButton<bool>(
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
              selected: <bool>{isLeft},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  isLeft = newSelection.first;
                });
                widget.onChange(isLeft);
              },
            )
          ],
        ),
      ),
    );
  }
}
