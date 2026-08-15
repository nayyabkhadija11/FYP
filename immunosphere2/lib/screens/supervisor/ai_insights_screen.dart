import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'ImmunoSphere AI Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF231B92),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF231B92), Color(0xFF4527A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Predictive Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AI-powered forecasting for vaccination dropouts, high-risk zones, and resource optimization.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Title
            const Text(
              'Key Risk Predictions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF231B92),
              ),
            ),
            const SizedBox(height: 12),

            // AI Insight Cards Grid / List
            _buildInsightCard(
              title: 'Predicted Dropout Risk',
              value: '12 Children',
              subtitle: 'High probability of missing the next scheduled polio booster.',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),

            _buildInsightCard(
              title: 'High-Risk Zone Alert',
              value: 'UC-4 North District',
              subtitle: 'Identified clusters with delayed vaccination history.',
              icon: Icons.location_on_outlined,
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            _buildInsightCard(
              title: 'Vaccine Supply Forecast',
              value: 'Optimal Stock',
              subtitle: 'Current inventory levels are sufficient for the upcoming weekly campaign.',
              icon: Icons.inventory_2_outlined,
              color: Colors.green,
            ),
            const SizedBox(height: 20),

            // Real-Time Firebase Predictive Data Stream Section
            const Text(
              'Live AI Logs & Recommendations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF231B92),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db.collection('notifications').limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No predictive alerts generated yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }

                  final logs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final logData = logs[index].data();
                      final message = logData['message'] ?? logData['title'] ?? 'AI System Update';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.auto_graph, color: Color(0xFF231B92), size: 20),
                          title: Text(
                            message,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Generated via AI Module',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}