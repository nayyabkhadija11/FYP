import 'package:flutter/material.dart';
import 'create_campaign_wizard_screen.dart';

class SupervisorCampaignsScreen extends StatelessWidget {
  const SupervisorCampaignsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('National Polio Campaign (Aug 2026)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('10 Aug 2026 - 15 Aug 2026\nHealth Centers: 3'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.green[100],
                child: const Text('Active',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006837),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateCampaignWizardScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}