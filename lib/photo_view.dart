import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PhotoView extends StatefulWidget {
  final String imageUrl;
  final AnimationController opacityController;
  final String heroTag;

  PhotoView({Key key, @required this.imageUrl, @required this.opacityController, this.heroTag})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => new _LoadMoreViewState();
}

const double kMinScale = 1.0;
const double kMaxScale = 3.0;

class _LoadMoreViewState extends State<PhotoView> with TickerProviderStateMixin {
  GlobalKey _imageKey = new GlobalKey();

  Offset _position;
  Offset _normalizedPosition;
  double _scale;
  double _scaleBefore;

  AnimationController _scaleAnimationController;
  Animation<double> _scaleAnimation;

  AnimationController _positionAnimationController;
  Animation<Offset> _positionAnimation;

  void handleScaleAnimation() {
    setState(() {
      _scale = _scaleAnimation.value;
    });
  }

  void handlePositionAnimate() {
    setState(() {
      _position = _positionAnimation.value;
    });
  }

  void onScaleStart(ScaleStartDetails details) {
    _scaleBefore = scaleStateAwareScale();
    _normalizedPosition = details.focalPoint - _position;
    _scaleAnimationController.stop();
    _positionAnimationController.stop();
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    final double newScale = _scaleBefore * details.scale;
    final Offset delta = details.focalPoint - _normalizedPosition;
    setState(() {
      _scale = newScale;
      _position = clampPosition(delta * details.scale);
    });
  }

  void onScaleEnd(ScaleEndDetails details) {
    final double maxScale = 3.0;
    final double minScale = 1.0;

    //animate back to maxScale if gesture exceeded the maxScale specified
    if (_scale > maxScale) {
      final double scaleComebackRatio = maxScale / _scale;
      animateScale(_scale, maxScale);
      animatePosition(_position, clampPosition(_position * scaleComebackRatio, maxScale));
      return;
    }

    //animate back to minScale if gesture fell smaller than the minScale specified
    if (_scale < minScale) {
      final double scaleComebackRatio = minScale / _scale;
      animateScale(_scale, minScale);
      animatePosition(_position, clampPosition(_position * scaleComebackRatio, maxScale));
      return;
    }
  }

  Offset clampPosition(Offset offset, [double scale]) {
    var imageSize = _imageKey.currentContext.findRenderObject().paintBounds.size;

    final double _scale = scale ?? scaleStateAwareScale();
    final double x = offset.dx;
    final double y = offset.dy;
    final double computedWidth = imageSize.width * _scale;
    final double computedHeight = imageSize.height * _scale;
    final double screenWidth = context.size.width;
    final double screenHeight = context.size.height;
    final double screenHalfX = screenWidth / 2;
    final double screenHalfY = screenHeight / 2;

    final double computedX = screenWidth < computedWidth
        ? x.clamp(0 - (computedWidth / 2) + screenHalfX, computedWidth / 2 - screenHalfX)
        : 0.0;

    final double computedY = screenHeight < computedHeight
        ? y.clamp(0 - (computedHeight / 2) + screenHalfY, computedHeight / 2 - screenHalfY)
        : 0.0;

    return Offset(computedX, computedY);
  }

  double scaleStateAwareScale() {
    return _scale;
  }

  void animateScale(double from, double to) {
    _scaleAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(_scaleAnimationController);
    _scaleAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void animatePosition(Offset from, Offset to) {
    _positionAnimation = Tween<Offset>(begin: from, end: to).animate(_positionAnimationController);
    _positionAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  @override
  void initState() {
    super.initState();
    _position = Offset.zero;
    _scale = 1.0;
    _scaleAnimationController = AnimationController(vsync: this)..addListener(handleScaleAnimation);

    _positionAnimationController = AnimationController(vsync: this)
      ..addListener(handlePositionAnimate);
  }

  @override
  void dispose() {
    _positionAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  // ==== 辅助动画/手势的计算
  int _lastTapTime = 0;

  _handleDoubleTap() {
    final double maxScale = 3.0;
    final double minScale = 1.0;

    //animate back to maxScale if gesture exceeded the maxScale specified
    if (_scale > 1.0) {
      animateScale(_scale, minScale);
      animatePosition(_position, Offset.zero);
    } else {
      final double scaleComebackRatio = maxScale / _scale;
      animateScale(_scale, maxScale);
      animatePosition(_position, clampPosition(_downPoint * scaleComebackRatio, maxScale));
    }
  }

  Offset _downPoint;

  @override
  Widget build(BuildContext context) {
    final transform = Matrix4.identity()
      ..translate(_position.dx, _position.dy)
      ..scale(scaleStateAwareScale());

    return new GestureDetector(
      onTapDown: (TapDownDetails details) {
        var half = context.size / 2.0;
        _downPoint = Offset(half.width, half.height) - details.globalPosition;
        _scaleAnimationController.stop();
        _positionAnimationController.stop();

        // Handle the gesture as a Double tap if the time between the double tap was in 500ms
        var tapTime = DateTime.now().millisecondsSinceEpoch;
        if (tapTime - _lastTapTime < 500) {
          _lastTapTime = 0;
          _handleDoubleTap();
        } else {
          _lastTapTime = tapTime;
        }
      },
//      onTap: () {
////          Navigator.of(context).pop();
//      },
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      child: new Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        alignment: Alignment.center,
        child: new Center(
          child: new Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _buildHero(),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return widget.heroTag != null ? Hero(tag: widget.heroTag, child: _buildImage()) : _buildImage();
  }

  Widget _buildImage() {
    return IgnorePointer(
      ignoringSemantics: true,
      child: new CachedNetworkImage(
        imageUrl: widget.imageUrl,
        key: _imageKey,
        placeholder: Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: Center(
          child: new Icon(Icons.image, size: 56.0),
        ),
      ),
    );
  }
}
