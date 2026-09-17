// ignore_for_file: library_private_types_in_public_api

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Lays [reading] out above [base] like ruby text (furigana).
///
/// Flutter has no ruby support, and stacking the two lines in a `Column`
/// misaligns the base: `RenderFlex` reports the baseline of its first child,
/// while `PlaceholderAlignment.bottom` only approximates it, leaving the base a
/// few pixels off the line's baseline. This widget reports the *base* child's
/// baseline instead, so it can be used with
/// `WidgetSpan(alignment: PlaceholderAlignment.baseline)`.
class RubyText extends MultiChildRenderObjectWidget {
  RubyText({
    super.key,
    required Widget reading,
    required Widget base,
    this.alignment = Alignment.center,
  }) : super(children: [reading, base]);

  /// How the reading is aligned above the base. Readings are usually wider than
  /// the characters they annotate, so they overhang.
  final AlignmentGeometry alignment;

  @override
  _RenderRubyText createRenderObject(BuildContext context) =>
      _RenderRubyText(alignment: alignment.resolve(Directionality.of(context)));

  @override
  void updateRenderObject(BuildContext context, _RenderRubyText renderObject) {
    renderObject.alignment = alignment.resolve(Directionality.of(context));
  }
}

class _RubyTextParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderRubyText extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RubyTextParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RubyTextParentData> {
  _RenderRubyText({required Alignment alignment}) : _alignment = alignment;

  Alignment _alignment;

  set alignment(Alignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  RenderBox get _reading => firstChild!;
  RenderBox get _base => lastChild!;

  // Child baselines are read during layout: querying a child while the
  // framework is already computing a baseline trips its debug assertion.
  double? _alphabeticBaseline;
  double? _ideographicBaseline;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RubyTextParentData) {
      child.parentData = _RubyTextParentData();
    }
  }

  @override
  void performLayout() {
    final reading = _reading;
    final base = _base;

    reading.layout(constraints.loosen(), parentUsesSize: true);
    base.layout(constraints, parentUsesSize: true);

    size = constraints.constrain(
      Size(
        math.max(reading.size.width, base.size.width),
        reading.size.height + base.size.height,
      ),
    );

    // The base sits below the reading and carries the baseline.
    final baseParentData = base.parentData! as _RubyTextParentData;
    baseParentData.offset = Offset(
      (size.width - base.size.width) / 2,
      reading.size.height,
    );

    final readingParentData = reading.parentData! as _RubyTextParentData;
    readingParentData.offset = Offset(switch (_alignment.x) {
      < 0 => 0.0,
      > 0 => size.width - reading.size.width,
      _ => (size.width - reading.size.width) / 2,
    }, 0);

    _alphabeticBaseline = base.getDistanceToBaseline(
      TextBaseline.alphabetic,
      onlyReal: true,
    );
    _ideographicBaseline = base.getDistanceToBaseline(
      TextBaseline.ideographic,
      onlyReal: true,
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final baseBaseline = baseline == TextBaseline.alphabetic
        ? _alphabeticBaseline
        : _ideographicBaseline;
    if (baseBaseline == null) return null;
    final baseParentData = _base.parentData! as _RubyTextParentData;
    return baseParentData.offset.dy + baseBaseline;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _RubyTextParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
