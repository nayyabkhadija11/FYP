import 'package:flutter/material.dart';
import 'create_campaign_wizard_screen.dart';

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({Key? key}) : super(key: key);

  static const Color primaryPurple = Color(0xFF3F2B96);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Good Morning',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text('Dr. Ahmed Khan',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: primaryPurple,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('ACTIVE CAMPAIGN',
                                style: TextStyle(
                                    color: primaryPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('National Polio Campaign (Aug 2026)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('10 Aug - 15 Aug 2026',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: primaryPurple),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard('Registered Children (All)', '482',
                          'Total unique children', Colors.blue[50]!),
                      const SizedBox(width: 12),
                      _buildStatCard('Active Campaigns', '3', 'Running',
                          Colors.purple[50]!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Today\'s Vaccinations',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Column(children: [
                                Text('Routine',
                                    style: TextStyle(color: Colors.grey)),
                                Text('32',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold))
                              ]),
                              Column(children: [
                                Text('Polio',
                                    style: TextStyle(color: Colors.grey)),
                                Text('320',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold))
                              ]),
                              Column(children: [
                                Text('Total',
                                    style: TextStyle(color: Colors.grey)),
                                Text('352',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryPurple))
                              ]),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Actions',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF006837)),
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text('Create Campaign',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateCampaignWizardScreen()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatCard(
      String title, String count, String sub, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(count,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(sub,
                style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}