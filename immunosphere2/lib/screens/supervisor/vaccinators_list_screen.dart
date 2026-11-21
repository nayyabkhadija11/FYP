import 'package:flutter/material.dart';
import 'vaccinator_details_screen.dart';

class VaccinatorsListScreen extends StatelessWidget {
  const VaccinatorsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Vaccinators', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          _buildVaccinatorItem(
              context, 'Maryam', 'VAC001', 'BHU Jand', '32', '85'),
          _buildVaccinatorItem(
              context, 'Ali Raza', 'VAC002', 'THQ Hospital Jand', '28', '62'),
          _buildVaccinatorItem(
              context, 'Zainab Bibi', 'VAC003', 'BHU Pindigheb', '16', '70'),
          _buildVaccinatorItem(
              context, 'Asif Khan', 'VAC004', 'RHC Hazro', '15', '68'),
        ],
      ),
    );
  }

  Widget _buildVaccinatorItem(BuildContext context, String name, String id,
      String center, String today, String week) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$id • $center\nToday: $today | This Week: $week'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VaccinatorDetailsScreen(
                  name: name, id: id, center: center),
            ),
          );
        },
      ),
    );
  }
}