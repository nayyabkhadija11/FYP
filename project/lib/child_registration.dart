import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChildRegistrationPage extends StatefulWidget {
  const ChildRegistrationPage({super.key});

  @override
  State<ChildRegistrationPage> createState() => _ChildRegistrationPageState();
}

class _ChildRegistrationPageState extends State<ChildRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final name = TextEditingController();
  final dobController = TextEditingController();
  final ageController = TextEditingController();
  final mother = TextEditingController();
  final cnic = TextEditingController();
  final address = TextEditingController();
  final district = TextEditingController();
  final contactNumber = TextEditingController();

  DateTime? selectedDate;
  String gender = "";
  String qrCode = "";
  bool loading = false;

  File? imageFile;
  String? imageUrl;
  final ImagePicker picker = ImagePicker();

  // --- IMPROVED CAMERA/GALLERY LOGIC ---
  Future<void> pickImage(ImageSource source) async {
    try {
      // imageQuality set karne se Firebase upload fast hota hai aur memory crash nahi hoti
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 50, // Optimize image for mobile
        maxWidth: 1000,
      );
      
      if (picked != null) {
        setState(() {
          imageFile = File(picked.path);
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to pick image: $e");
      _showSnackBar("Permission denied or error occurred");
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text("Select Image", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Take Photo from Camera"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- AGE CALCULATION ---
  String calculateDetailedAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    int days = today.day - birthDate.day;

    if (days < 0) {
      months -= 1;
      int previousMonth = today.month - 1 == 0 ? 12 : today.month - 1;
      int yearOfPrevMonth = today.month - 1 == 0 ? today.year - 1 : today.year;
      int daysInPrevMonth = DateTime(yearOfPrevMonth, previousMonth + 1, 0).day;
      days += daysInPrevMonth;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    
    List<String> parts = [];
    if (years > 0) parts.add("$years Y");
    if (months > 0) parts.add("$months M");
    if (years == 0 && months == 0) parts.add("$days D");
    
    return parts.isEmpty ? "0 D" : parts.join(", ");
  }

  Future<void> pickDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dobController.text = "${picked.day}-${picked.month}-${picked.year}";
        ageController.text = calculateDetailedAge(picked);
      });
    }
  }

  // --- FIREBASE LOGIC ---
  Future<String> uploadImage(File file) async {
    String fileName = "children/${DateTime.now().millisecondsSinceEpoch}.jpg";
    Reference ref = FirebaseStorage.instance.ref().child(fileName);
    UploadTask task = ref.putFile(file);
    TaskSnapshot snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> saveChild() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      _showSnackBar("Please fill all fields and select DOB");
      return;
    }
    if (gender.isEmpty) {
      _showSnackBar("Please select gender");
      return;
    }

    setState(() => loading = true);
    
    try {
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile!);
      }

      await FirebaseFirestore.instance.collection("children").add({
        "name": name.text.trim(),
        "dob": selectedDate,
        "age_display": ageController.text.trim(),
        "mother": mother.text.trim(),
        "motherCNIC": cnic.text.trim(),
        "address": address.text.trim(),
        "gender": gender,
        "district": district.text.trim(),
        "contact": contactNumber.text.trim(),
        "qrCode": "CH-${DateTime.now().millisecondsSinceEpoch}",
        "imageUrl": imageUrl ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar("Child Registered Successfully");
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Child Registration", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Picker
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
                            child: imageFile == null 
                                ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _showImageSourceOptions,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    _buildTextField(name, "Child Name", Icons.person),
                    _buildTextField(dobController, "Date of Birth", Icons.calendar_today, readOnly: true, onTap: pickDOB),
                    _buildTextField(ageController, "Calculated Age", Icons.timer, readOnly: true),
                    _buildTextField(mother, "Mother's Name", Icons.woman),
                    _buildTextField(cnic, "Mother CNIC", Icons.badge, 
                        keyboard: TextInputType.number, 
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13), _CnicFormatter()]),
                    _buildTextField(address, "Address", Icons.home),
                    
                    DropdownButtonFormField<String>(
                      value: gender.isEmpty ? null : gender,
                      items: ["Male", "Female", "Other"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => gender = v!),
                      decoration: _dec("Gender", Icons.wc),
                      validator: (v) => v == null ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    
                    _buildTextField(district, "District", Icons.location_city),
                    _buildTextField(contactNumber, "Contact Number", Icons.phone, 
                        keyboard: TextInputType.phone, 
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11), _PhoneFormatter()]),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: saveChild,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("SAVE REGISTRATION", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool readOnly = false, VoidCallback? onTap, TextInputType? keyboard, List<TextInputFormatter>? formatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboard,
        inputFormatters: formatters,
        decoration: _dec(hint, icon),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      labelText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
    );
  }
}

// --- FORMATTERS ---
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll('-', '');
    String result = "";
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) result += "-";
      result += digits[i];
    }
    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll('-', '');
    if (digits.length > 4) {
      String res = "${digits.substring(0, 4)}-${digits.substring(4)}";
      return TextEditingValue(text: res, selection: TextSelection.collapsed(offset: res.length));
    }
    return newValue;
  }
}