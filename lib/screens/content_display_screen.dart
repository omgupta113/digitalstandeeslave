// lib/screens/content_display_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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

  Future<void> _initializeScreen() async {
    // Update slave status and setup content stream
    try {
      await _slaveService.updateStatus(widget.slaveId, true);
      _setupContentStream();
    } catch (e) {
      debugPrint('Error initializing screen: $e');
    }
  }

  void _setupContentStream() {
    // Cancel any existing subscription
    _contentSubscription?.cancel();

    _contentSubscription = _slaveService.getContent(widget.slaveId).listen(
          (contents) {
        // Check if widget is still mounted before updating state
        if (!_isDisposed) {
          setState(() {
            _contentList = contents;
            // Reset index if needed and show content
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
      cancelOnError: false, // Don't cancel subscription on error
    );
  }

  Future<void> _showCurrentContent() async {
    if (_isDisposed || _contentList.isEmpty) return;

    // Cancel existing timer
    _contentTimer?.cancel();

    // Clean up previous video
    await _cleanupVideo();

    if (_isDisposed) return;

    final content = _contentList[_currentIndex];

    // Handle video content
    if (content.type == 'video') {
      await _setupVideo(content.url);
    }

    if (_isDisposed) return;

    // Schedule next content
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

    // Cancel timer
    _contentTimer?.cancel();

    // Cancel stream subscription
    _contentSubscription?.cancel();

    // Clean up video controller
    if (_videoController != null) {
      _videoController!.dispose();
    }

    // Update slave status
    _slaveService.updateStatus(widget.slaveId, false).catchError((error) {
      debugPrint('Error updating slave status: $error');
    });

    super.dispose();
  }

  Widget _buildContentWidget(Content content) {
    switch (content.type) {
      case 'image'or'png'or'jpg'or'jpeg':
        return CachedNetworkImage(
          imageUrl: content.url,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );

      case 'video'or'mp4':
        if (_videoController != null && _isVideoInitialized) {
          return AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          );
        }
        return const Center(child: CircularProgressIndicator());

      case 'pdf':
        return SfPdfViewer.network(
          content.url,
          enableDoubleTapZooming: false,
        );

      default:
        return Center(
          child: Text('Unsupported content type: ${content.type}'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: _contentList.isEmpty
            ? const Center(
          child: Text('Waiting for content...'),
        )
            : _buildContentWidget(_contentList[_currentIndex]),
      ),
    );
  }
}