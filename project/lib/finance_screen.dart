import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  // Colors from the image
  final Color primaryOrange = const Color(0xFFE67E22);
  final Color headerOrange = const Color(0xFFD35400);
  final Color bgLight = const Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          // 1. Orange Header Section
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Stats Row (Total Budget, Disbursed, etc.)
                  _buildStatsRow(),
                  const SizedBox(height: 20),

                  // 3. Navigation Tabs (Vaccinator Payments, District Budget, etc.)
                  _buildTabSwitcher(),
                  const SizedBox(height: 20),

                  // 4. Data Table Container
                  _buildPaymentTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryOrange, headerOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Finance & Payment Module",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text("Salary Management & Budget Tracking", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text("Export"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard("Total Budget", "Rs 15,000,000", Icons.attach_money, Colors.blue),
          _statCard("Disbursed", "Rs 8,450,000", Icons.check_circle_outline, Colors.green),
          _statCard("Pending", "Rs 3,250,000", Icons.schedule, Colors.orange),
          _statCard("Reserved", "Rs 3,300,000", Icons.lock_outline, Colors.purple),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Icon(icon, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _tabItem("Vaccinator Payments", true),
          _tabItem("District Budget", false),
          _tabItem("Monthly Expenses", false),
        ],
      ),
    );
  }

  Widget _tabItem(String title, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Vaccinator Payment Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('District')),
                DataColumn(label: Text('Vaccinated')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                _tableRow("V001", "Ali Ahmed", "Lahore", "287", "Rs 14,350", "paid", Colors.green),
                _tableRow("V002", "Fatima Shah", "Faisalabad", "265", "Rs 13,250", "paid", Colors.green),
                _tableRow("V003", "Hassan Raza", "Rawalpindi", "258", "Rs 12,900", "pending", Colors.orange),
                _tableRow("V004", "Ayesha Khan", "Multan", "245", "Rs 12,250", "pending", Colors.orange),
                _tableRow("V005", "Usman Ali", "Lahore", "232", "Rs 11,600", "processing", Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _tableRow(String id, String name, String dist, String count, String amt, String status, Color statusColor) {
    return DataRow(cells: [
      DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(name)),
      DataCell(Text(dist)),
      DataCell(Text(count)),
      DataCell(Text(amt, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
      )),
      DataCell(
        status == "paid" 
        ? const Text("2026-04-15", style: TextStyle(color: Colors.grey, fontSize: 12))
        : ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.grey), elevation: 0),
            child: const Text("Process", style: TextStyle(color: Colors.black, fontSize: 12)),
          ),
      ),
    ]);
  }
}