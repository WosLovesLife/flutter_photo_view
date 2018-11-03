import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PhotoView extends StatefulWidget {
  final String imageUrl;
  final AnimationController opacityController;

  PhotoView({Key key, @required this.imageUrl, @required this.opacityController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _LoadMoreViewState();
}

const double kMinScale = 1.0;
const double kMaxScale = 3.0;

class _LoadMoreViewState extends State<PhotoView> with TickerProviderStateMixin {
  GlobalKey _imageKey = new GlobalKey();

  AnimationController _controller;
  CurvedAnimation _curvedAnimation;
  Tween<double> _scaleTween;
  Tween<Offset> _positionTween;

  // 放大/和放大的基点的值. 在动画/手势中会实时变化
  double _scale = kMinScale;
  Offset _position = Offset.zero;

  // ==== 辅助动画/手势的计算
  int _lastTapTime = 0;
  Offset _downPoint = Offset.zero;
  Offset _downPosition = Offset.zero;

  /// 上次放大的比例, 用于帮助下次放大操作时放大的速度保持一致.
  double _lastScaleValue = kMinScale;
  Offset _lastPosition = Offset.zero;

  @override
  void initState() {
    super.initState();

    _controller = new AnimationController(duration: new Duration(milliseconds: 300), vsync: this)
      ..addListener(_handleScaleAnim);

    _curvedAnimation = new CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
  }

  _forwardAnimations() {
    _scaleTween = new Tween<double>(begin: _scale, end: kMaxScale);

    var containerSize = MediaQuery.of(context).size;
    var center = new Offset(containerSize.width, containerSize.height) / 2.0;
    var delta = center - _downPoint;
    var positionDelta = (delta * kMaxScale);
    _positionTween = new Tween<Offset>(begin: _position, end: _clampPosition(positionDelta, 3.0));
  }

  _resetAnimations() {
    _scaleTween = new Tween<double>(begin: _scale, end: kMinScale);
    _positionTween = new Tween<Offset>(begin: _position, end: Offset.zero);
  }

  _handleScaleAnim() {
    var newScale = _scaleTween.evaluate(_curvedAnimation);
    setState(() {
      _scale = newScale;
      _position = _positionTween.evaluate(_curvedAnimation);
    });
  }

  Offset _clampPosition(Offset offset, double scale) {
    var imageSize = _imageKey.currentContext.findRenderObject().paintBounds.size;

    final x = offset.dx;
    final y = offset.dy;
    final computedWidth = imageSize.width * scale;
    final computedHeight = imageSize.height * scale;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenHalfX = screenWidth / 2;
    final screenHalfY = screenHeight / 2;

    final double computedX = screenWidth < computedWidth
        ? x.clamp(0 - (computedWidth / 2) + screenHalfX, computedWidth / 2 - screenHalfX)
        : 0.0;

    final double computedY = screenHeight < computedHeight
        ? y.clamp(0 - (computedHeight / 2) + screenHalfY, computedHeight / 2 - screenHalfY)
        : 0.0;

    return new Offset(computedX, computedY);
  }

  // ======== handle gesture

  _handleDoubleTap() {
    if (_scale > kMinScale) {
      _resetAnimations();
    } else {
      _forwardAnimations();
    }

    _controller.reset();
    _controller.forward();
  }

  _handleScaleStart(ScaleStartDetails details) {
    _downPoint = details.focalPoint;
    _lastScaleValue = _scale;
    _lastPosition = details.focalPoint - _position;
    _downPosition = _position;
    // 计算出当前图像的中心点距离屏幕中心点的距离
  }

  _handleScaleUpdate(ScaleUpdateDetails details) {
    double newScale = (_lastScaleValue * details.scale);

    if (newScale < kMinScale) {
      newScale = kMinScale;
    } else if (newScale > kMaxScale) {
      newScale = kMaxScale;
    }

    var deltaScale = _lastScaleValue - newScale;
    var ratio = deltaScale / (kMaxScale - kMinScale);
    var dx = _downPosition.dx - ratio * _downPosition.dx;
    var dy = _downPosition.dy - ratio * _downPosition.dy;

    final Offset positionDelta = (details.focalPoint - _lastPosition);

    setState(() {
      _scale = newScale;
      _position = _clampPosition(Offset(dx, dy), _scale);

      // 表示没有缩放操作才响应平移操作
      if (_lastScaleValue == _scale) {
        _position = _clampPosition(positionDelta, _scale);
      }
    });
  }

  _handleScaleEnd(ScaleEndDetails details) {}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Matrix4 transform = new Matrix4.identity()
      ..translate(_position.dx, _position.dy)
      ..scale(_scale, _scale, 1.0);

    return new GestureDetector(
      onTapDown: (TapDownDetails details) {
        _downPoint = details.globalPosition;
        _controller.stop();

        // Handle the gesture as a Double tap if the time between the double tap was in 500ms
        var tapTime = DateTime.now().millisecondsSinceEpoch;
        if (tapTime - _lastTapTime < 500) {
          _lastTapTime = 0;
          _handleDoubleTap();
        } else {
          _lastTapTime = tapTime;
        }
      },
      onTap: () {
//          Navigator.of(context).pop();
      },
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: new Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        alignment: Alignment.center,
        child: new Wrap(
          children: <Widget>[
            new Transform(
              transform: transform,
              alignment: Alignment.center,
              child: IgnorePointer(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
