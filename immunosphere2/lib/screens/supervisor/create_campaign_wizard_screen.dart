import 'package:flutter/material.dart';

class CreateCampaignWizardScreen extends StatefulWidget {
  const CreateCampaignWizardScreen({Key? key}) : super(key: key);

  @override
  State<CreateCampaignWizardScreen> createState() =>
      _CreateCampaignWizardScreenState();
}

class _CreateCampaignWizardScreenState
    extends State<CreateCampaignWizardScreen> {
  int _currentStep = 1;
  static const Color primaryGreen = Color(0xFF006837);

  void _nextStep() {
    if (_currentStep < 9) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevStep,
        ),
        title: Text(_getStepTitle(),
            style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildWizardContent(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                onPressed: _nextStep,
                child: Text(_getButtonText(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Create Campaign';
      case 2:
        return 'Select Target Area';
      case 3:
        return 'Children in Area';
      case 4:
        return 'Assign Vaccinators / Team';
      case 5:
        return 'Auto Assignment Preview';
      case 6:
        return 'Campaign Summary';
      case 7:
        return 'Campaign Overview';
      case 8:
        return 'Team Assignment Details';
      case 9:
        return 'Campaign Started';
      default:
        return 'Campaign Wizard';
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Next: Select Target Area';
      case 2:
        return 'Next: View Children';
      case 3:
        return 'Next: Assign Vaccinators';
      case 4:
        return 'Next: Auto Assign';
      case 5:
        return 'Confirm & Create Campaign';
      case 6:
        return 'Start Campaign';
      case 7:
        return 'View Assignment Details';
      case 8:
        return 'Proceed to Confirmation';
      case 9:
        return 'Go to Campaign Overview';
      default:
        return 'Next';
    }
  }

  Widget _buildWizardContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Campaign Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            TextField(
                decoration: InputDecoration(
                    labelText: 'Campaign Name', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(
                decoration: InputDecoration(
                    labelText: 'Campaign Type (e.g. Polio)',
                    border: OutlineInputBorder())),
          ],
        );
      case 2:
        return Column(
          children: const [
            ListTile(
                title: Text('Mohallah A, Jand'),
                subtitle: Text('Total Children: 128 (0-5 Years)'),
                leading: Icon(Icons.radio_button_checked, color: primaryGreen)),
            ListTile(
                title: Text('Mohallah B, Jand'),
                subtitle: Text('Total Children: 95 (0-5 Years)'),
                leading: Icon(Icons.radio_button_off)),
          ],
        );
      case 3:
        return Card(
          color: Colors.green[50],
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('Total Children'),
                  Text('128',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ]),
                Column(children: [
                  Text('Total Households'),
                  Text('80',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ]),
              ],
            ),
          ),
        );
      case 4:
        return Column(
          children: const [
            CheckboxListTile(
                value: true,
                onChanged: null,
                title: Text('Ahmed Khan'),
                subtitle: Text('ID: VAC-001')),
            CheckboxListTile(
                value: true,
                onChanged: null,
                title: Text('Fatima Noor'),
                subtitle: Text('ID: VAC-002')),
          ],
        );
      case 5:
        return const ListTile(
          title: Text('Team A Assignment Preview'),
          subtitle: Text(
              'Ahmed Khan: 50 Houses (64 Children)\nFatima Noor: 30 Houses (64 Children)'),
        );
      case 6:
        return Column(
          children: const [
            Icon(Icons.assignment_turned_in, size: 60, color: primaryGreen),
            SizedBox(height: 8),
            Text('Campaign Ready!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        );
      case 7:
        return const ListTile(
          title: Text('National Polio Campaign'),
          subtitle: Text('Active • 128 Children • 80 Households'),
        );
      case 8:
        return Column(
          children: const [
            ListTile(title: Text('House #12'), subtitle: Text('Children: 2')),
            ListTile(title: Text('House #15'), subtitle: Text('Children: 1')),
          ],
        );
      case 9:
        return Column(
          children: const [
            Icon(Icons.check_circle, size: 80, color: primaryGreen),
            SizedBox(height: 16),
            Text('Campaign Started Successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}