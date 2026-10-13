import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

mixin CallVideoHandler {
  bool isCameraOff = false;
  bool isRemoteCameraOff = false;
  bool isLocalFullScreen = false;
  bool isLoadingRemoteVideo = true;
  MediaStream? localStream;
  MediaStream? remoteStream;
  late final RTCVideoRenderer localRenderer;
  late final RTCVideoRenderer remoteRenderer;

  Future<void> initRenderers() async {
    localRenderer = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (e) {
      debugPrint("⚠️ Renderer init error: $e");
    }
  }

  void disposeRenderers() {
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      localRenderer.dispose();
      remoteRenderer.dispose();
    } catch (_) {}
  }
}
