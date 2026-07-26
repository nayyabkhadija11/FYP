/*import 'package:flutter/material.dart';
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

  // 🔥 DUPLICATE CHECK (MAIN FIX)
  Future<bool> isDuplicateEntry() async {
    final result = await FirebaseFirestore.instance
        .collection("vaccinations")
        .where("motherCNIC", isEqualTo: cnicController.text.trim())
        .where("vaccineType", isEqualTo: vaccineType)
        .where("doseNumber", isEqualTo: doseNumber)
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

    String cnic = cnicController.text.trim();

    // ✔ 1. CHILD CHECK
    bool exists = await checkChildExists(cnic);

    if (!exists) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Child not registered!")),
      );
      return;
    }

    // 🔥 2. DUPLICATE CHECK (IMPORTANT)
    bool duplicate = await isDuplicateEntry();

    if (duplicate) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This vaccine dose already exists for this child!"),
        ),
      );
      return;
    }

    // ✔ 3. SAVE DATA
    await FirebaseFirestore.instance.collection("vaccinations").add({
      "childName": childNameController.text.trim(),
      "motherCNIC": cnic,
      "vaccineType": vaccineType,
      "doseNumber": doseNumber,
      "status": status,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    childNameController.clear();
    cnicController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vaccination Saved Successfully")),
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
                labelText: "Mother CNIC",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: vaccineType,
              items: ["BCG", "OPV", "IPV", "Pentavalent", "PCV", "Rotavirus", "Measles/MR", "Hepatitis B", "Dengvaxia"]
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
              items: ["Dose 1", "Dose 2", "Dose 3", "Dose 4"]
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
}*//*
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

  // ✅ CHECK CHILD EXISTS (UNIQUE CNIC SYSTEM)
  Future<bool> isChildRegistered(String cnic) async {
    final result = await FirebaseFirestore.instance
        .collection("children")
        .where("motherCNIC", isEqualTo: cnic)
        .get();

    return result.docs.isNotEmpty;
  }

  // 🔥 DUPLICATE CHECK (vaccine + dose + child)
  Future<bool> isDuplicateEntry() async {
    final result = await FirebaseFirestore.instance
        .collection("vaccinations")
        .where("motherCNIC", isEqualTo: cnicController.text.trim())
        .where("vaccineType", isEqualTo: vaccineType)
        .where("doseNumber", isEqualTo: doseNumber)
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

    String cnic = cnicController.text.trim();

    // ✔ 1. CHILD MUST EXIST (CNIC UNIQUE)
    bool childExists = await isChildRegistered(cnic);

    if (!childExists) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Child not registered with this CNIC!"),
        ),
      );
      return;
    }

    // ✔ 2. DUPLICATE ENTRY BLOCK
    bool duplicate = await isDuplicateEntry();

    if (duplicate) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This vaccine dose already exists for this child!"),
        ),
      );
      return;
    }

    // ✔ 3. SAVE DATA
    await FirebaseFirestore.instance.collection("vaccinations").add({
      "childName": childNameController.text.trim(),
      "motherCNIC": cnic,
      "vaccineType": vaccineType,
      "doseNumber": doseNumber,
      "status": status,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    childNameController.clear();
    cnicController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vaccination Saved Successfully")),
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
                labelText: "Mother CNIC",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: vaccineType,
              items: ["BCG", "OPV", "IPV", "Pentavalent", "PCV", "Rotavirus", "Measles/MR", "Hepatitis B", "Dengvaxia"]
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
              items: ["Dose 1", "Dose 2", "Dose 3", "Dose 4"]
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
                  backgroundColor: const Color(0xFF004AAD),
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

  // 🔥 Variables ko null rakha hai taake dropdown ke andar Hint show ho sake
  String? vaccineType;
  String? doseNumber;
  String? status;

  bool loading = false;

  Future<bool> isChildRegistered(String cnic) async {
    final result = await FirebaseFirestore.instance
        .collection("children")
        .where("motherCNIC", isEqualTo: cnic)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> isDuplicateEntry() async {
    final result = await FirebaseFirestore.instance
        .collection("vaccinations")
        .where("motherCNIC", isEqualTo: cnicController.text.trim())
        .where("vaccineType", isEqualTo: vaccineType)
        .where("doseNumber", isEqualTo: doseNumber)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<void> saveVaccination() async {
    // Dropdown validation update ki hai
    if (childNameController.text.isEmpty || 
        cnicController.text.isEmpty || 
        vaccineType == null || 
        doseNumber == null || 
        status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select all options")),
      );
      return;
    }

    setState(() => loading = true);
    String cnic = cnicController.text.trim();

    bool childExists = await isChildRegistered(cnic);
    if (!childExists) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Child not registered with this CNIC!")),
      );
      return;
    }

    bool duplicate = await isDuplicateEntry();
    if (duplicate) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This vaccine dose already exists!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("vaccinations").add({
      "childName": childNameController.text.trim(),
      "motherCNIC": cnic,
      "vaccineType": vaccineType,
      "doseNumber": doseNumber,
      "status": status,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vaccination Saved Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF004AAD);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vaccination Entry", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
      ),
      body: SingleChildScrollView(
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
            const SizedBox(height: 15),

            TextField(
              controller: cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CnicFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "Mother CNIC",
                hintText: "12345-1234567-1",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 💉 VACCINE TYPE DROPDOWN
            DropdownButtonFormField<String>(
              value: vaccineType,
              hint: const Text("Select Vaccine Type"), // Ye label ki tarah pehle show hoga
              items: ["BCG", "OPV", "IPV", "Pentavalent", "PCV", "Rotavirus", "Measles/MR", "Hepatitis B", "Dengvaxia"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => vaccineType = val),
              decoration: const InputDecoration(
                labelText: "Vaccine Type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 🔢 DOSE DROPDOWN
            DropdownButtonFormField<String>(
              value: doseNumber,
              hint: const Text("Select Dose Number"), // Ye label ki tarah pehle show hoga
              items: ["Dose 1", "Dose 2", "Dose 3", "Dose 4"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => doseNumber = val),
              decoration: const InputDecoration(
                labelText: "Dose",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // ✅ STATUS DROPDOWN
            DropdownButtonFormField<String>(
              value: status,
              hint: const Text("Select Status"), // Ye label ki tarah pehle show hoga
              items: ["completed", "refused", "absent"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => status = val),
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : saveVaccination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE VACCINATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
  // 🔥 Controllers
  final TextEditingController childIdController = TextEditingController(); // Nayi Field
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  String? vaccineType;
  String? doseNumber;
  String? status;

  bool loading = false;

  // ✨ Check if Child exists using ID and Mother's CNIC
  Future<bool> isChildRegistered(String id, String cnic) async {
    final result = await FirebaseFirestore.instance
        .collection("children")
        .where("childId", isEqualTo: id) // Child ID se check
        .where("motherCNIC", isEqualTo: cnic)
        .get();
    return result.docs.isNotEmpty;
  }

  // ✨ Check for Duplicate Vaccination Entry
  Future<bool> isDuplicateEntry() async {
    final result = await FirebaseFirestore.instance
        .collection("vaccinations")
        .where("childId", isEqualTo: childIdController.text.trim())
        .where("vaccineType", isEqualTo: vaccineType)
        .where("doseNumber", isEqualTo: doseNumber)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<void> saveVaccination() async {
    if (childIdController.text.isEmpty || 
        childNameController.text.isEmpty || 
        cnicController.text.isEmpty || 
        vaccineType == null || 
        doseNumber == null || 
        status == null) {
      _showSnackBar("Please fill all fields and select all options");
      return;
    }

    setState(() => loading = true);
    
    String cId = childIdController.text.trim();
    String cnic = cnicController.text.trim();

    // 1. Check Registration
    bool childExists = await isChildRegistered(cId, cnic);
    if (!childExists) {
      setState(() => loading = false);
      _showSnackBar("Child ID not found with this CNIC!");
      return;
    }

    // 2. Check Duplicates
    bool duplicate = await isDuplicateEntry();
    if (duplicate) {
      setState(() => loading = false);
      _showSnackBar("This vaccine dose already exists for this child!");
      return;
    }

    try {
      // 3. Save Data
      await FirebaseFirestore.instance.collection("vaccinations").add({
        "childId": cId,
        "childName": childNameController.text.trim(),
        "motherCNIC": cnic,
        "vaccineType": vaccineType,
        "doseNumber": doseNumber,
        "status": status,
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar("Vaccination Saved Successfully");
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF004AAD);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vaccination Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🆔 CHILD ID FIELD (NEW)
            TextField(
              controller: childIdController,
              decoration: const InputDecoration(
                labelText: "Child Registration ID",
                prefixIcon: Icon(Icons.qr_code, color: primaryBlue),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: childNameController,
              decoration: const InputDecoration(
                labelText: "Child Name",
                prefixIcon: Icon(Icons.person, color: primaryBlue),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
                _CnicFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "Mother CNIC",
                hintText: "12345-1234567-1",
                prefixIcon: Icon(Icons.badge, color: primaryBlue),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // 💉 VACCINE TYPE DROPDOWN
            DropdownButtonFormField<String>(
              value: vaccineType,
              hint: const Text("Select Vaccine Type"),
              items: ["BCG", "OPV", "IPV", "Pentavalent", "PCV", "Rotavirus", "Measles/MR", "Hepatitis B"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => vaccineType = val),
              decoration: const InputDecoration(
                labelText: "Vaccine Type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 🔢 DOSE DROPDOWN
            DropdownButtonFormField<String>(
              value: doseNumber,
              hint: const Text("Select Dose Number"),
              items: ["Dose 1", "Dose 2", "Dose 3", "Dose 4"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => doseNumber = val),
              decoration: const InputDecoration(
                labelText: "Dose",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // ✅ STATUS DROPDOWN
            DropdownButtonFormField<String>(
              value: status,
              hint: const Text("Select Status"),
              items: ["completed", "refused", "absent"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => status = val),
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : saveVaccination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE VACCINATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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