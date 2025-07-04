import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tennis_serve_analysis/controllers/user_controller.dart';

class HeightPicker extends ConsumerStatefulWidget {
  final int minHeight;
  final int maxHeight;
  int get totalUnits => maxHeight - minHeight;
  const HeightPicker({super.key, this.minHeight = 155, this.maxHeight = 210});

  @override
  ConsumerState createState() => _HeightPickerState();
}

class _HeightPickerState extends ConsumerState<HeightPicker> {
  double startDragYOffset = 0;
  int startDragHeight = 0;
  double widgetHeight = 0;

  int _normalizeHeight(int height) {
    return math.max(widget.minHeight, math.min(widget.maxHeight, height));
  }

  double get _pixelsPerUnit {
    return _drawingHeight / widget.totalUnits;
  }

  double get _sliderPosition {
    const double halfOfBottomLabel = 13 / 2; //13 is the font size
    final int unitsFromBottom =
        ref.read(userServeDataProvider).height - widget.minHeight;
    return halfOfBottomLabel + unitsFromBottom * _pixelsPerUnit;
  }

  double get _drawingHeight {
    const double marginBottom = 16;
    const double marginTop = 26;
    return widgetHeight - (marginBottom + marginTop + 13); //13 is the font size
  }

  int _globalOffsetToHeight(Offset globalOffset) {
    final RenderBox getBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = getBox.globalToLocal(globalOffset);
    double dy = localPosition.dy;
    dy = dy - 26 - 13 / 2;
    final int height = widget.maxHeight - (dy ~/ _pixelsPerUnit);
    return height;
  }

  void _onTapDown(TapDownDetails tapDownDetails) {
    _normalizeHeight(ref.read(userServeDataProvider).height);
  }

  void _onDragStart(DragStartDetails dragStartDetails) {
    ref
        .read(userServeDataProvider.notifier)
        .onHeightChanged(
          _globalOffsetToHeight(dragStartDetails.globalPosition),
        );
    startDragYOffset = dragStartDetails.globalPosition.dy;
    startDragHeight = ref.read(userServeDataProvider).height;
  }

  void _onDragUpdate(DragUpdateDetails dragUpdateDetails) {
    final double currentYOffset = dragUpdateDetails.globalPosition.dy;
    final double verticalDifference = startDragYOffset - currentYOffset;
    final int diffHeight = verticalDifference ~/ _pixelsPerUnit;
    ref
        .read(userServeDataProvider.notifier)
        .onHeightChanged(_normalizeHeight(startDragHeight + diffHeight));
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
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                "${ref.read(userServeDataProvider).heightInFeetAndInches()} / ${ref.read(userServeDataProvider).height} cm",
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
                const Expanded(
                  child: SizedBox(
                    height: 2,
                    width: double.infinity,
                    child: ColoredBox(color: Colors.indigo),
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
    final int labelsToDisplay = widget.totalUnits ~/ 5 + 1;
    final List<Widget> labels = List.generate(labelsToDisplay, (idx) {
      return Text(
        "${widget.maxHeight - 5 * idx}",
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      );
    });

    return Align(
      alignment: Alignment.centerRight,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 16, top: 26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels,
          ),
        ),
      ),
    );
  }

  Widget _drawPersonImage() {
    final double personImageHeight = _sliderPosition + 19;
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
    ref.watch(userServeDataProvider.select((value) => value.height));
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "HEIGHT",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "(cm)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 0, color: Colors.grey),
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
