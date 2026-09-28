import 'package:flutter/material.dart';

/// 日記写真をピンチとボタンで拡大縮小して見る。
class PhotoViewer extends StatefulWidget {
  final ImageProvider image;

  const PhotoViewer({super.key, required this.image});

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final _controller = TransformationController();
  static const _minScale = 1.0;
  static const _maxScale = 4.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomBy(double factor) {
    final current = _controller.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(_minScale, _maxScale);
    if (next == current) return;
    final ratio = next / current;
    _controller.value = _controller.value.clone()..scaleByDouble(ratio, ratio, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _zoomBy(1 / 1.5),
            icon: const Icon(Icons.zoom_out),
            tooltip: '縮小',
          ),
          IconButton(
            onPressed: () => _zoomBy(1.5),
            icon: const Icon(Icons.zoom_in),
            tooltip: '拡大',
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _controller,
        minScale: _minScale,
        maxScale: _maxScale,
        child: Center(
          child: Image(image: widget.image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
