import 'package:flutter/material.dart';
import 'package:tennis_serve_analysis/models/serve_result.dart';

class ReferencePlayerCard extends StatelessWidget {
  final ServeResult referencePlayerResult;
  final bool isSelected;
  const ReferencePlayerCard(
      {Key? key, required this.referencePlayerResult, this.isSelected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: (isSelected) ? Colors.green.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                referencePlayerResult.playerPhotoAssetPath!,
                height: 70,
                width: 70,
                fit: BoxFit.scaleDown,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referencePlayerResult.playerName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.straighten),
                      const SizedBox(width: 4),
                      Text(referencePlayerResult.heightInFeetAndInches()),
                      const Spacer(),
                      const Icon(Icons.sports_tennis),
                      const SizedBox(width: 4),
                      Text(referencePlayerResult.isLeftHanded
                          ? "Left Handed"
                          : "Right Handed"),
                      const SizedBox(width: 4),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
