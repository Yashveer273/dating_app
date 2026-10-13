import 'package:flutter_webrtc/flutter_webrtc.dart';

mixin CallAudioHandler {
  bool isMuted = false;
  bool isAgentMuted = false;
  bool isUserMuted = false;
  bool isSpeakerOn = false;
  MediaStream? localStream;

  bool get isRemoteMuted; // Main controller से मिलेगा

  void toggleMutedLogic() {
    isMuted = !isMuted;
    if (localStream != null) {
      for (var track in localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  void toggleSpeakerLogic() {
    isSpeakerOn = !isSpeakerOn;
    Helper.setSpeakerphoneOn(isSpeakerOn);
  }
}
