import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';

class HeightPicker extends StatefulWidget {
  final int initialHeight;
  final int minHeight;
  final int maxHeight;
  final ValueChanged<int> onHeightChanged;

  int get totalUnits => maxHeight - minHeight;

  const HeightPicker({
    Key? key,
    this.initialHeight = 185,
    this.minHeight = 155,
    this.maxHeight = 210,
    required this.onHeightChanged,
  }) : super(key: key);

  @override
  HeightPickerState createState() => HeightPickerState();
}

class HeightPickerState extends State<HeightPicker> {
  late int height;
  double startDragYOffset = 0;
  int startDragHeight = 0;
  double widgetHeight = 0;

  @override
  void initState() {
    super.initState();
    height = widget.initialHeight;
  }

  int _normalizeHeight(int height) {
    return math.max(widget.minHeight, math.min(widget.maxHeight, height));
  }

  double get _pixelsPerUnit {
    return _drawingHeight / widget.totalUnits;
  }

  double get _sliderPosition {
    double halfOfBottomLabel = 13 / 2; //13 is the font size
    int unitsFromBottom = height - widget.minHeight;
    return halfOfBottomLabel + unitsFromBottom * _pixelsPerUnit;
  }

  double get _drawingHeight {
    double marginBottom = 16;
    double marginTop = 26;
    return widgetHeight - (marginBottom + marginTop + 13); //13 is the font size
  }

  int _globalOffsetToHeight(Offset globalOffset) {
    RenderBox getBox = context.findRenderObject() as RenderBox;
    Offset localPosition = getBox.globalToLocal(globalOffset);
    double dy = localPosition.dy;
    dy = dy - 26 - 13 / 2;
    int height = widget.maxHeight - (dy ~/ _pixelsPerUnit);
    return height;
  }

  void _onTapDown(TapDownDetails tapDownDetails) {
    setState(() {
      _normalizeHeight(height);
    });
  }

  void _onDragStart(DragStartDetails dragStartDetails) {
    setState(() {
      height = _globalOffsetToHeight(dragStartDetails.globalPosition);
      startDragYOffset = dragStartDetails.globalPosition.dy;
      startDragHeight = height;
    });
  }

  void _onDragUpdate(DragUpdateDetails dragUpdateDetails) {
    double currentYOffset = dragUpdateDetails.globalPosition.dy;
    double verticalDifference = startDragYOffset - currentYOffset;
    int diffHeight = verticalDifference ~/ _pixelsPerUnit;
    setState(() {
      height = _normalizeHeight(startDragHeight + diffHeight);
    });
  }

  Widget _drawSlider() {
    return AnimatedPositioned(
      left: 0.0,
      right: 0.0,
      bottom: _sliderPosition,
      duration: const Duration(milliseconds: 100),
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                bottom: 2,
              ),
              child: Text(
                "$height cm",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.unfold_more,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawLabels() {
    int labelsToDisplay = widget.totalUnits ~/ 5 + 1;
    List<Widget> labels = List.generate(
      labelsToDisplay,
      (idx) {
        return Text(
          "${widget.maxHeight - 5 * idx}",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        );
      },
    );

    return Align(
      alignment: Alignment.centerRight,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.only(
            right: 12,
            bottom: 16,
            top: 26,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels,
          ),
        ),
      ),
    );
  }

  Widget _drawPersonImage() {
    double personImageHeight = _sliderPosition + 19;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        height: personImageHeight,
        width: personImageHeight / 3,
        duration: const Duration(milliseconds: 100),
        child: SvgPicture.asset("assets/images/person.svg"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    "HEIGHT",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "(cm)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 0,
              color: Colors.grey,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    widgetHeight = constraints.maxHeight;
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: _onTapDown,
                      onVerticalDragStart: _onDragStart,
                      onVerticalDragUpdate: _onDragUpdate,
                      child: Stack(
                        children: [
                          _drawPersonImage(),
                          _drawSlider(),
                          _drawLabels(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
