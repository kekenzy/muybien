import 'package:flutter/material.dart';

/// 写真をピンチとボタンで拡大縮小して見る。複数枚あるときは左右スワイプで切り替える。
class PhotoViewer extends StatefulWidget {
  final List<ImageProvider> images;
  final int initialIndex;

  const PhotoViewer({super.key, required this.images, this.initialIndex = 0});

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  static const _minScale = 1.0;
  static const _maxScale = 4.0;

  late final PageController _pageController;
  late final List<TransformationController> _controllers;
  late int _index;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);
    _controllers = [
      for (var i = 0; i < widget.images.length; i++)
        TransformationController()..addListener(_onTransform),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController get _current => _controllers[_index];

  // 拡大中はスワイプを画像の移動に使うため、ページ送りを止める
  void _onTransform() {
    final zoomed = _current.value.getMaxScaleOnAxis() > _minScale + 0.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _onPageChanged(int index) {
    _current.value = Matrix4.identity();
    setState(() {
      _index = index;
      _zoomed = false;
    });
  }

  void _zoomBy(double factor) {
    final current = _current.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(_minScale, _maxScale);
    if (next == current) return;
    final ratio = next / current;
    _current.value = _current.value.clone()..scaleByDouble(ratio, ratio, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: count > 1
            ? Text('${_index + 1} / $count', style: const TextStyle(fontSize: 16))
            : null,
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
      body: PageView.builder(
        controller: _pageController,
        physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
        itemCount: count,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => InteractiveViewer(
          transformationController: _controllers[index],
          minScale: _minScale,
          maxScale: _maxScale,
          child: Center(
            child: Image(image: widget.images[index], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
