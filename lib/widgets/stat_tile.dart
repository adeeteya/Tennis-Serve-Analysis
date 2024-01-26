import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  final String assetPath;
  final String statTitle;
  final double angle;
  final double? referenceAngle;
  const StatTile(
      {super.key,
      required this.assetPath,
      required this.statTitle,
      required this.angle,
      this.referenceAngle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset(
          assetPath,
          height: 32,
          width: 32,
          fit: BoxFit.scaleDown,
        ),
        title: Text(statTitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${angle.round()}°",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.red),
            ),
            const SizedBox(width: 15),
            Text(
              (referenceAngle != null) ? "${referenceAngle?.round()}°" : "NaN",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
