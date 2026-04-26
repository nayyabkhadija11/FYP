/*import 'package:flutter/material.dart';
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

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

            // ✅ CNIC FIELD WITH FORMAT
            TextField(
              controller: cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                _CnicFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "CNIC (xxxxx-xxxxxxx-x)",
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

// ================= CNIC FORMATTER =================
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll('-', '');

    String result = "";
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) result += "-";
      result += digits[i];
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

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

  // ✅ CHECK CHILD EXISTS
  Future<bool> checkChildExists(String cnic) async {
    final result = await FirebaseFirestore.instance
        .collection("children")
        .where("cnic", isEqualTo: cnic)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> saveVaccination() async {
    if (childNameController.text.isEmpty || cnicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    // 🔴 STEP 1: CHECK CHILD
    bool exists = await checkChildExists(cnicController.text.trim());

    if (!exists) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Child not registered! Please register first."),
        ),
      );
      return;
    }

    // ✅ STEP 2: SAVE IF EXISTS
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                _CnicFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "CNIC (xxxxx-xxxxxxx-x)",
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

// ================= CNIC FORMATTER =================
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll('-', '');

    String result = "";
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) result += "-";
      result += digits[i];
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class VaccinationEntryPage extends StatefulWidget {
  const VaccinationEntryPage({super.key});

  @override
  State<VaccinationEntryPage> createState() => _VaccinationEntryPageState();
}

class _VaccinationEntryPageState extends State<VaccinationEntryPage> {
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  String vaccineType = "BCG";
  String doseNumber = "Dose 1";
  String status = "completed";

  bool loading = false;

  // ✅ CHECK CHILD EXISTS
  Future<bool> checkChildExists(String cnic) async {
    final result = await FirebaseFirestore.instance
        .collection("children")
        .where("motherCNIC", isEqualTo: cnic)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> saveVaccination() async {
    if (childNameController.text.isEmpty || cnicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    bool exists = await checkChildExists(cnicController.text.trim());

    if (!exists) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Child not registered! Please register first."),
        ),
      );
      return;
    }

    // ✅ SAVE DATA (FIXED FIELD NAME)
    await FirebaseFirestore.instance.collection("vaccinations").add({
      "childName": childNameController.text.trim(),
      "motherCNIC": cnicController.text.trim(), // ✅ FIXED HERE
      "vaccineType": vaccineType.trim().toUpperCase(),
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                _CnicFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "Mother CNIC (xxxxx-xxxxxxx-x)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: vaccineType,
              items: ["BCG", "OPV", "IPV", "Pentavalent", "PCV","Rotavirus","Measles/MR","Hepatitis B","Dengvaxia"]
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
              items: ["Dose 1", "Dose 2", "Dose 3","Dose 4"]
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

// ================= CNIC FORMATTER =================
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll('-', '');

    String result = "";
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) result += "-";
      result += digits[i];
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}