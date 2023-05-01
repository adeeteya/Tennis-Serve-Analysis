import 'package:flutter/material.dart';
import 'package:tennis_serve_analysis/finals.dart';
import 'package:tennis_serve_analysis/widgets/reference_player_card.dart';

class ChangeReferencePlayerScreen extends StatefulWidget {
  final int selectedPlayerIndex;
  const ChangeReferencePlayerScreen(
      {Key? key, required this.selectedPlayerIndex})
      : super(key: key);

  @override
  State<ChangeReferencePlayerScreen> createState() =>
      _ChangeReferencePlayerScreenState();
}

class _ChangeReferencePlayerScreenState
    extends State<ChangeReferencePlayerScreen> {
  late int selectedIndex;

  @override
  void initState() {
    selectedIndex = widget.selectedPlayerIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Reference Player"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, selectedIndex);
        },
        child: const Icon(Icons.done),
      ),
      body: ListView.builder(
        itemCount: availableReferencePlayers.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: ReferencePlayerCard(
              referencePlayerResult: availableReferencePlayers[index],
              isSelected: index == selectedIndex,
            ),
          ),
        ),
      ),
    );
  }
}
