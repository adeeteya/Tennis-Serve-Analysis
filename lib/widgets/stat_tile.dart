import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  final String assetPath;
  final String statTitle;
  final double angle;
  const StatTile(
      {Key? key,
      required this.assetPath,
      required this.statTitle,
      required this.angle})
      : super(key: key);

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
        trailing: Text(
          "${angle.toStringAsFixed(2)}°",
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
