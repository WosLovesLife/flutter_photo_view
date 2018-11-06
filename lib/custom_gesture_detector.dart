// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_photo_view/custom_tap.dart';

export 'package:flutter/gestures.dart'
    show
        DragDownDetails,
        DragStartDetails,
        DragUpdateDetails,
        DragEndDetails,
        GestureTapDownCallback,
        GestureTapUpCallback,
        GestureTapCallback,
        GestureTapCancelCallback,
        GestureLongPressCallback,
        GestureDragDownCallback,
        GestureDragStartCallback,
        GestureDragUpdateCallback,
        GestureDragEndCallback,
        GestureDragCancelCallback,
        GestureScaleStartCallback,
        GestureScaleUpdateCallback,
        GestureScaleEndCallback,
        ScaleStartDetails,
        ScaleUpdateDetails,
        ScaleEndDetails,
        TapDownDetails,
        TapUpDetails,
        Velocity;

/// A widget that detects gestures.
///
/// Attempts to recognize gestures that correspond to its non-null callbacks.
///
/// If this widget has a child, it defers to that child for its sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// By default a GestureDetector with an invisible child ignores touches;
/// this behavior can be controlled with [behavior].
///
/// GestureDetector also listens for accessibility events and maps
/// them to the callbacks. To ignore accessibility events, set
/// [excludeFromSemantics] to true.
///
/// See <http://flutter.io/gestures/> for additional information.
///
/// Material design applications typically react to touches with ink splash
/// effects. The [InkWell] class implements this effect and can be used in place
/// of a [CustomGestureDetector] for handling taps.
///
/// ## Sample code
///
/// This example makes a rectangle react to being tapped by setting the
/// `_lights` field:
///
/// ```dart
/// GestureDetector(
///   onTap: () {
///     setState(() { _lights = true; });
///   },
///   child: Container(
///     color: Colors.yellow,
///     child: Text('TURN LIGHTS ON'),
///   ),
/// )
/// ```
///
/// ## Debugging
///
/// To see how large the hit test box of a [CustomGestureDetector] is for debugging
/// purposes, set [debugPaintPointersEnabled] to true.
class CustomGestureDetector extends StatelessWidget {
  /// Creates a widget that detects gestures.
  ///
  /// Pan and scale callbacks cannot be used simultaneously because scale is a
  /// superset of pan. Simply use the scale callbacks instead.
  ///
  /// Horizontal and vertical drag callbacks cannot be used simultaneously
  /// because a combination of a horizontal and vertical drag is a pan. Simply
  /// use the pan callbacks instead.
  ///
  /// By default, gesture detectors contribute semantic information to the tree
  /// that is used by assistive technology.
  CustomGestureDetector(
      {Key key,
      this.child,
      this.onTouchDown,
      this.onTapDown,
      this.onTapUp,
      this.onTap,
      this.onTapCancel,
      this.onDoubleTap,
      this.onLongPress,
      this.onLongPressUp,
      this.onVerticalDragDown,
      this.onVerticalDragStart,
      this.onVerticalDragUpdate,
      this.onVerticalDragEnd,
      this.onVerticalDragCancel,
      this.onHorizontalDragDown,
      this.onHorizontalDragStart,
      this.onHorizontalDragUpdate,
      this.onHorizontalDragEnd,
      this.onHorizontalDragCancel,
      this.onPanDown,
      this.onPanStart,
      this.onPanUpdate,
      this.onPanEnd,
      this.onPanCancel,
      this.onScaleStart,
      this.onScaleUpdate,
      this.onScaleEnd,
      this.behavior,
      this.excludeFromSemantics = false})
      : assert(excludeFromSemantics != null),
        assert(() {
          final bool haveVerticalDrag = onVerticalDragStart != null ||
              onVerticalDragUpdate != null ||
              onVerticalDragEnd != null;
          final bool haveHorizontalDrag = onHorizontalDragStart != null ||
              onHorizontalDragUpdate != null ||
              onHorizontalDragEnd != null;
          final bool havePan = onPanStart != null || onPanUpdate != null || onPanEnd != null;
          final bool haveScale =
              onScaleStart != null || onScaleUpdate != null || onScaleEnd != null;
          if (havePan || haveScale) {
            if (havePan && haveScale) {
              throw FlutterError('Incorrect GestureDetector arguments.\n'
                  'Having both a pan gesture recognizer and a scale gesture recognizer is redundant; scale is a superset of pan. Just use the scale gesture recognizer.');
            }
            final String recognizer = havePan ? 'pan' : 'scale';
            if (haveVerticalDrag && haveHorizontalDrag) {
              throw FlutterError('Incorrect GestureDetector arguments.\n'
                  'Simultaneously having a vertical drag gesture recognizer, a horizontal drag gesture recognizer, and a $recognizer gesture recognizer '
                  'will result in the $recognizer gesture recognizer being ignored, since the other two will catch all drags.');
            }
          }
          return true;
        }()),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A pointer that might cause a tap has contacted the screen at a particular
  /// location.
  ///
  /// This is called after a short timeout, even if the winning gesture has not
  /// yet been selected. If the tap gesture wins, [onTapUp] will be called,
  /// otherwise [onTapCancel] will be called.
  final GestureTapDownCallback onTapDown;

  // Custom gesture event callback
  // invoke when touch down on screen
  final GestureTapDownCallback onTouchDown;

  /// A pointer that will trigger a tap has stopped contacting the screen at a
  /// particular location.
  ///
  /// This triggers immediately before [onTap] in the case of the tap gesture
  /// winning. If the tap gesture did not win, [onTapCancel] is called instead.
  final GestureTapUpCallback onTapUp;

  /// A tap has occurred.
  ///
  /// This triggers when the tap gesture wins. If the tap gesture did not win,
  /// [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [onTapUp], which is called at the same time but includes details
  ///    regarding the pointer position.
  final GestureTapCallback onTap;

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  ///
  /// This is called after [onTapDown], and instead of [onTapUp] and [onTap], if
  /// the tap gesture did not win.
  final GestureTapCancelCallback onTapCancel;

  /// The user has tapped the screen at the same location twice in quick
  /// succession.
  final GestureTapCallback onDoubleTap;

  /// A pointer has remained in contact with the screen at the same location for
  /// a long period of time.
  final GestureLongPressCallback onLongPress;

  /// A pointer that has triggered a long-press has stopped contacting the screen.
  final GestureLongPressUpCallback onLongPressUp;

  /// A pointer has contacted the screen and might begin to move vertically.
  final GestureDragDownCallback onVerticalDragDown;

  /// A pointer has contacted the screen and has begun to move vertically.
  final GestureDragStartCallback onVerticalDragStart;

  /// A pointer that is in contact with the screen and moving vertically has
  /// moved in the vertical direction.
  final GestureDragUpdateCallback onVerticalDragUpdate;

  /// A pointer that was previously in contact with the screen and moving
  /// vertically is no longer in contact with the screen and was moving at a
  /// specific velocity when it stopped contacting the screen.
  final GestureDragEndCallback onVerticalDragEnd;

  /// The pointer that previously triggered [onVerticalDragDown] did not
  /// complete.
  final GestureDragCancelCallback onVerticalDragCancel;

  /// A pointer has contacted the screen and might begin to move horizontally.
  final GestureDragDownCallback onHorizontalDragDown;

  /// A pointer has contacted the screen and has begun to move horizontally.
  final GestureDragStartCallback onHorizontalDragStart;

  /// A pointer that is in contact with the screen and moving horizontally has
  /// moved in the horizontal direction.
  final GestureDragUpdateCallback onHorizontalDragUpdate;

  /// A pointer that was previously in contact with the screen and moving
  /// horizontally is no longer in contact with the screen and was moving at a
  /// specific velocity when it stopped contacting the screen.
  final GestureDragEndCallback onHorizontalDragEnd;

  /// The pointer that previously triggered [onHorizontalDragDown] did not
  /// complete.
  final GestureDragCancelCallback onHorizontalDragCancel;

  /// A pointer has contacted the screen and might begin to move.
  final GestureDragDownCallback onPanDown;

  /// A pointer has contacted the screen and has begun to move.
  final GestureDragStartCallback onPanStart;

  /// A pointer that is in contact with the screen and moving has moved again.
  final GestureDragUpdateCallback onPanUpdate;

  /// A pointer that was previously in contact with the screen and moving
  /// is no longer in contact with the screen and was moving at a specific
  /// velocity when it stopped contacting the screen.
  final GestureDragEndCallback onPanEnd;

  /// The pointer that previously triggered [onPanDown] did not complete.
  final GestureDragCancelCallback onPanCancel;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  final GestureScaleStartCallback onScaleStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  final GestureScaleUpdateCallback onScaleUpdate;

  /// The pointers are no longer in contact with the screen.
  final GestureScaleEndCallback onScaleEnd;

  /// How this gesture detector should behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.deferToChild] if [child] is not null and
  /// [HitTestBehavior.translucent] if child is null.
  final HitTestBehavior behavior;

  /// Whether to exclude these gestures from the semantics tree. For
  /// example, the long-press gesture for showing a tooltip is
  /// excluded because the tooltip itself is included in the semantics
  /// tree directly and so having a gesture to show it would result in
  /// duplication of information.
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};

    if (onTapDown != null || onTapUp != null || onTap != null || onTapCancel != null) {
      gestures[CustomTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<CustomTapGestureRecognizer>(
        () => CustomTapGestureRecognizer(debugOwner: this),
        (CustomTapGestureRecognizer instance) {
          instance
            ..onTouchDown = onTouchDown
            ..onTapDown = onTapDown
            ..onTapUp = onTapUp
            ..onTap = onTap
            ..onTapCancel = onTapCancel;
        },
      );
    }

    if (onDoubleTap != null) {
      gestures[DoubleTapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
        () => DoubleTapGestureRecognizer(debugOwner: this),
        (DoubleTapGestureRecognizer instance) {
          instance..onDoubleTap = onDoubleTap;
        },
      );
    }

    if (onLongPress != null || onLongPressUp != null) {
      gestures[LongPressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(debugOwner: this),
        (LongPressGestureRecognizer instance) {
          instance
            ..onLongPress = onLongPress
            ..onLongPressUp = onLongPressUp;
        },
      );
    }

    if (onVerticalDragDown != null ||
        onVerticalDragStart != null ||
        onVerticalDragUpdate != null ||
        onVerticalDragEnd != null ||
        onVerticalDragCancel != null) {
      gestures[VerticalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(debugOwner: this),
        (VerticalDragGestureRecognizer instance) {
          instance
            ..onDown = onVerticalDragDown
            ..onStart = onVerticalDragStart
            ..onUpdate = onVerticalDragUpdate
            ..onEnd = onVerticalDragEnd
            ..onCancel = onVerticalDragCancel;
        },
      );
    }

    if (onHorizontalDragDown != null ||
        onHorizontalDragStart != null ||
        onHorizontalDragUpdate != null ||
        onHorizontalDragEnd != null ||
        onHorizontalDragCancel != null) {
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(debugOwner: this),
        (HorizontalDragGestureRecognizer instance) {
          instance
            ..onDown = onHorizontalDragDown
            ..onStart = onHorizontalDragStart
            ..onUpdate = onHorizontalDragUpdate
            ..onEnd = onHorizontalDragEnd
            ..onCancel = onHorizontalDragCancel;
        },
      );
    }

    if (onPanDown != null ||
        onPanStart != null ||
        onPanUpdate != null ||
        onPanEnd != null ||
        onPanCancel != null) {
      gestures[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(debugOwner: this),
        (PanGestureRecognizer instance) {
          instance
            ..onDown = onPanDown
            ..onStart = onPanStart
            ..onUpdate = onPanUpdate
            ..onEnd = onPanEnd
            ..onCancel = onPanCancel;
        },
      );
    }

    if (onScaleStart != null || onScaleUpdate != null || onScaleEnd != null) {
      gestures[ScaleGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        () => ScaleGestureRecognizer(debugOwner: this),
        (ScaleGestureRecognizer instance) {
          instance
            ..onStart = onScaleStart
            ..onUpdate = onScaleUpdate
            ..onEnd = onScaleEnd;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}
