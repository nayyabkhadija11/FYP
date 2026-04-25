import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationEntryPage extends StatefulWidget {
  const VaccinationEntryPage({super.key});

  @override
  State<VaccinationEntryPage> createState() => _VaccinationEntryPageState();
}

class _VaccinationEntryPageState extends State<VaccinationEntryPage> {
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  String vaccineType = "Polio";
  String doseNumber = "Dose 1";
  String status = "completed";

  bool loading = false;

  Future<void> saveVaccination() async {
    if (childNameController.text.isEmpty || cnicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("vaccinations").add({
      "childName": childNameController.text.trim(),
      "cnic": cnicController.text.trim(),
      "vaccineType": vaccineType,
      "doseNumber": doseNumber,
      "status": status,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    childNameController.clear();
    cnicController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vaccination Saved")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vaccination Entry"),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: childNameController,
              decoration: const InputDecoration(
                labelText: "Child Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: cnicController,
              decoration: const InputDecoration(
                labelText: "CNIC",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: vaccineType,
              items: ["Polio", "BCG", "Hepatitis", "Measles"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => vaccineType = val!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Vaccine Type",
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: doseNumber,
              items: ["Dose 1", "Dose 2", "Dose 3"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => doseNumber = val!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Dose",
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: status,
              items: ["completed", "refused", "absent"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => status = val!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Status",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : saveVaccination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Vaccination"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}