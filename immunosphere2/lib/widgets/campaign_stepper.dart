import 'package:flutter/material.dart';

class CampaignStepper extends StatelessWidget {
  final int currentStep; // 1-5
  static const Color primaryGreen = Color(0xFF006837);

  const CampaignStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          int stepNum = index + 1;
          bool isActive = currentStep >= stepNum;
          return Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isActive ? primaryGreen : Colors.grey.shade300,
                child: Text(
                  "$stepNum",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
              if (stepNum < 5)
                Container(
                  width: 24,
                  height: 2,
                  color: currentStep > stepNum ? primaryGreen : Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          );
        }),
      ),
    );
  }
}