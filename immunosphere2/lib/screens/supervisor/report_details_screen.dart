import 'package:flutter/material.dart';

class ReportDetailsScreen extends StatelessWidget {
  final String reportTitle;

  const ReportDetailsScreen({Key? key, required this.reportTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(reportTitle),
        backgroundColor: const Color(0xFF3F2B96),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 80, color: Color(0xFF3F2B96)),
            const SizedBox(height: 16),
            Text(reportTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F2B96)),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('Download PDF Report',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}