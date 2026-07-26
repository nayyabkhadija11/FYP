import 'package:flutter/material.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  final Color primaryTeal = const Color(0xFF0D9488);
  final Color bgSlate = const Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildKpiGrid(),
                  const SizedBox(height: 24),
                  _buildSimpleChartSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Supervisor Dashboard",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Real-time Vaccination Monitoring",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // KPI CARDS
  Widget _buildKpiGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard("Total Children", "45,280", Colors.blue),
        _statCard("Vaccinated", "38,456", Colors.green),
        _statCard("Pending", "4,824", Colors.orange),
        _statCard("Refused", "2,000", Colors.red),
        _statCard("Coverage", "84.9%", Colors.purple),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    double width = (MediaQuery.of(context).size.width / 2) - 22;

    return Container(
      width: title == "Coverage" ? double.infinity : width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // SIMPLE CHART (NO PACKAGE)
  Widget _buildSimpleChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vaccination Progress (Mock Chart)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // SIMPLE BAR GRAPH USING CONTAINERS
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bar("Mon", 0.6, Colors.green),
              _bar("Tue", 0.8, Colors.green),
              _bar("Wed", 0.4, Colors.orange),
              _bar("Thu", 0.7, Colors.green),
              _bar("Fri", 0.9, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double heightFactor, Color color) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}