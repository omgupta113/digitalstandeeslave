import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/slave_service.dart';
import '../models/content.dart';
import 'dart:async';

class ContentDisplayScreen extends StatefulWidget {
  final String slaveId;

  const ContentDisplayScreen({Key? key, required this.slaveId}) : super(key: key);

  @override
  _ContentDisplayScreenState createState() => _ContentDisplayScreenState();
}

class _ContentDisplayScreenState extends State<ContentDisplayScreen> {
  final SlaveService _slaveService = SlaveService();
  List<Content> _contentList = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Timer? _contentTimer;
  StreamSubscription? _contentSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Widget _buildIdleScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child:RotatedBox(
            quarterTurns: 1,
            child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Slave ID',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.slaveId,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: widget.slaveId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scan QR Code to get Slave ID',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Waiting for content...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Device Online',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }


  Future<void> _initializeScreen() async {
    try {
      await _slaveService.updateStatus(widget.slaveId, true);
      _setupContentStream();
    } catch (e) {
      debugPrint('Error initializing screen: $e');
    }
  }

  void _setupContentStream() {
    _contentSubscription?.cancel();

    _contentSubscription = _slaveService.getContent(widget.slaveId).listen(
          (contents) {
        if (!_isDisposed) {
          setState(() {
            _contentList = contents;
            if (_contentList.isNotEmpty) {
              if (_currentIndex >= _contentList.length) {
                _currentIndex = 0;
              }
              _showCurrentContent();
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Error in content stream: $error');
      },
      cancelOnError: false,
    );
  }

  Future<void> _showCurrentContent() async {
    if (_isDisposed || _contentList.isEmpty) return;

    _contentTimer?.cancel();
    await _cleanupVideo();

    if (_isDisposed) return;

    final content = _contentList[_currentIndex];

    if (content.type == 'video') {
      await _setupVideo(content.url);
    }

    if (_isDisposed) return;

    _contentTimer = Timer(
      Duration(seconds: content.displayDuration),
          () {
        if (!_isDisposed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _contentList.length;
            _showCurrentContent();
          });
        }
      },
    );
  }

  Future<void> _cleanupVideo() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      if (!_isDisposed) {
        setState(() {
          _videoController = null;
          _isVideoInitialized = false;
        });
      }
    }
  }

  Future<void> _setupVideo(String url) async {
    try {
      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();

      if (!_isDisposed) {
        setState(() => _isVideoInitialized = true);
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      await _cleanupVideo();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _contentTimer?.cancel();
    _contentSubscription?.cancel();

    if (_videoController != null) {
      _videoController!.dispose();
    }

    _slaveService.updateStatus(widget.slaveId, false).catchError((error) {
      debugPrint('Error updating slave status: $error');
    });

    super.dispose();
  }

  Widget _buildContentWidget(Content content) {
    String contentType = content.type.toLowerCase();

    Widget contentWidget;

    if (contentType == 'image' ||
        contentType == 'png' ||
        contentType == 'jpg' ||
        contentType == 'jpeg') {
      contentWidget = CachedNetworkImage(
        imageUrl: content.url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else if (contentType == 'video' || contentType == 'mp4') {
      if (_videoController != null && _isVideoInitialized) {
        contentWidget = AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      } else {
        contentWidget = const CircularProgressIndicator();
      }
    } else if (contentType == 'pdf') {
      contentWidget = SfPdfViewer.network(
        content.url,
        enableDoubleTapZooming: false,
      );
    } else {
      contentWidget = Text('Unsupported content type: ${content.type}');
    }

    return Center(
      child: RotatedBox(
        quarterTurns: 2,
        child: Center(child: contentWidget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: Center(
            child: _contentList.isEmpty
                ? _buildIdleScreen()
                : _buildContentWidget(_contentList[_currentIndex]),
          ),
        ),
      ),
    );
  }
}