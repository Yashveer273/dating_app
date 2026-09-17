// views/role_selection_view.dart
import 'package:flutter/material.dart';
import './call_api_service.dart';
import 'user_call_view.dart';
import 'agent_call_view.dart';

class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select App Role (Simulation)")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Choose how you want to log in:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 1. LOGIN AS USER -> Opens User Call View (Agent List with Call/Video buttons)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueAccent,
              ),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text(
                "Login as User",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserCallView()),
                );
              },
            ),
            const SizedBox(height: 20),

            // 2. LOGIN AS AGENT
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
              ),
              icon: const Icon(Icons.support_agent, color: Colors.white),
              label: const Text(
                "Login as Agent",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentCallView(
                      realAgentId: CallApiService.staticAgentId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
