// views/caling_agent_dashboard/callreceive/CallReactionHandler.dart

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class FloatingReactionIcon {
  final int id;
  final IconData icon;
  final Color color;
  final double startX;
  FloatingReactionIcon({
    required this.id,
    required this.icon,
    required this.color,
    required this.startX,
  });
}

mixin CallReactionHandler {
  final List<FloatingReactionIcon> floatingReactions = [];

  IO.Socket? get socket;
  String get roomIdRef; // 🟢 इसे कंट्रोलर के roomId से सही से मैप किया गया है
  VoidCallback
  get onStateUpdatedRef; // 🟢 इसे onStateUpdated से मैप किया गया है

  final Map<String, Map<String, dynamic>> reactionConfig = {
    'heart': {'icon': Icons.favorite, 'color': Colors.redAccent},
    'fire': {'icon': Icons.local_fire_department, 'color': Colors.orangeAccent},
    'star': {'icon': Icons.star, 'color': Colors.amber},
    'thumb': {'icon': Icons.thumb_up, 'color': Colors.pinkAccent},
    'sparkle': {'icon': Icons.auto_awesome, 'color': Colors.purpleAccent},
  };

  void sendReaction(String iconKey) {
    // 1. अपनी खुद की स्क्रीन पर तुरंत दिखाएं (Sender UI)
    triggerReactionAnimation(iconKey);

    // 2. सॉकेट के जरिए सामने वाले को भेजें (Chrome से Mobile या Mobile से Chrome)
    if (socket != null && socket!.connected) {
      socket!.emit('send-reaction', {'roomId': roomIdRef, 'iconKey': iconKey});
      debugPrint("❤️ [REACTION SENT] Key: $iconKey to Room: $roomIdRef");
    }
  }

  void triggerReactionAnimation(String iconKey) {
    final config = reactionConfig[iconKey];
    if (config == null) return;

    final double randomX = 50.0 + (DateTime.now().millisecond % 250);

    final reaction = FloatingReactionIcon(
      id: DateTime.now().millisecondsSinceEpoch + DateTime.now().microsecond,
      icon: config['icon'] as IconData,
      color: config['color'] as Color,
      startX: randomX,
    );

    floatingReactions.add(reaction);

    // 🟢 UI को तुरंत फोर्सफुली अपडेट करें ताकि दोनों (Web & Mobile) पर दिखे
    onStateUpdatedRef();

    // 2.5 सेकंड बाद रिएक्शन को लिस्ट से हटा दें
    Future.delayed(const Duration(milliseconds: 2500), () {
      floatingReactions.removeWhere((item) => item.id == reaction.id);
      onStateUpdatedRef();
    });
  }

  void initReactionListener() {
    socket?.off(
      'receive-reaction',
    ); // डुप्लीकेट लिसनर रोकने के लिए पहले साफ करें
    socket?.on('receive-reaction', (data) {
      debugPrint("📥 [REACTION RECEIVED FROM SOCKET]: $data");
      if (data != null && data['iconKey'] != null) {
        triggerReactionAnimation(data['iconKey'].toString());
      }
    });
  }
}
