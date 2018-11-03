import 'package:flutter/material.dart';
import 'package:flutter_photo_view/photo_view.dart';

void main() => runApp(new MaterialApp(
      title: 'Mei Zi',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new TestPhotoView(),
    ));

class TestPhotoView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _TestPhotoViewState();
  }
}

class _TestPhotoViewState extends State<TestPhotoView> with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new PhotoView(
      imageUrl: 'http://ww2.sinaimg.cn/large/610dc034jw1f3rbikc83dj20dw0kuadt.jpg',
//      imageUrl: 'http://img.soogif.com/YpEcZKVZvshJEC2dSrWAXQkhFDjBSyqR.gif',
      opacityController: controller,
    );
  }
}
