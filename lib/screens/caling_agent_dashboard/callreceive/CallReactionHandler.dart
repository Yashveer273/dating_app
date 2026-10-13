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
  String get roomId;
  VoidCallback get onStateUpdated;

  final Map<String, Map<String, dynamic>> reactionConfig = {
    'heart': {'icon': Icons.favorite, 'color': Colors.redAccent},
    'fire': {'icon': Icons.local_fire_department, 'color': Colors.orangeAccent},
    'star': {'icon': Icons.star, 'color': Colors.amber},
    'thumb': {'icon': Icons.thumb_up, 'color': Colors.pinkAccent},
    'sparkle': {'icon': Icons.auto_awesome, 'color': Colors.purpleAccent},
  };

  void sendReaction(String iconKey) {
    // 1. Local screen पर तुरंत दिखाएं
    triggerReactionAnimation(iconKey);

    // 2. Socket के जरिए सामने वाले (Receiver) को भेजें
    socket?.emit('send-reaction', {'roomId': roomId, 'iconKey': iconKey});
  }

  void triggerReactionAnimation(String iconKey) {
    final config = reactionConfig[iconKey];
    if (config == null) return;

    // रैंडम X पोजीशन जनरेट करें
    final double randomX = 50.0 + (DateTime.now().millisecond % 250);

    final reaction = FloatingReactionIcon(
      id: DateTime.now().millisecondsSinceEpoch,
      icon: config['icon'] as IconData,
      color: config['color'] as Color,
      startX: randomX,
    );

    floatingReactions.add(reaction);
    onStateUpdated();

    // 2.5 सेकंड बाद रिएक्शन को लिस्ट से हटा दें
    Future.delayed(const Duration(milliseconds: 2500), () {
      floatingReactions.removeWhere((item) => item.id == reaction.id);
      onStateUpdated();
    });
  }

  void initReactionListener() {
    socket?.on('receive-reaction', (data) {
      if (data != null && data['iconKey'] != null) {
        triggerReactionAnimation(data['iconKey'].toString());
      }
    });
  }
}
