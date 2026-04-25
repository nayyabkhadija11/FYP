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

  final name = TextEditingController();
  final dob = TextEditingController();
  final mother = TextEditingController();
  final cnic = TextEditingController();
  final address = TextEditingController();
  final district = TextEditingController();
  final contactNumber = TextEditingController();

  String gender = "";
  String qrCode = "";
  bool loading = false;

  // ✅ NEW: IMAGE FILE + URL
  File? imageFile;
  String? imageUrl;

  final ImagePicker picker = ImagePicker();

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // ---------------- UPLOAD IMAGE ----------------
  Future<String> uploadImage(File file) async {
    String fileName = "children/${DateTime.now().millisecondsSinceEpoch}.jpg";

    UploadTask task = FirebaseStorage.instance
        .ref()
        .child(fileName)
        .putFile(file);

    TaskSnapshot snapshot = await task;

    return await snapshot.ref.getDownloadURL();
  }

  String generateQR() {
    return "CH-${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<void> pickDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dob.text = "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  Future<void> saveChild() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      qrCode = generateQR();
    });

    try {
      // ✅ upload image first
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile!);
      }

      await FirebaseFirestore.instance.collection("children").add({
        "name": name.text.trim(),
        "dob": dob.text.trim(),
        "mother": mother.text.trim(),
        "cnic": cnic.text.trim(),
        "address": address.text.trim(),
        "gender": gender,
        "district": district.text.trim(),
        "contact": contactNumber.text.trim(),
        "qrCode": qrCode,
        "imageUrl": imageUrl ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Child Registered Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Child Registration"),
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

                    // ---------------- IMAGE UPLOAD (NEW UI) ----------------
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          image: imageFile != null
                              ? DecorationImage(
                                  image: FileImage(imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: 40, color: Colors.blue),
                                  SizedBox(height: 5),
                                  Text("Upload Child Photo"),
                                ],
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ---------------- EXISTING FIELDS (UNCHANGED) ----------------
                    TextFormField(
                      controller: name,
                      decoration: _dec("Child Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),

                    TextFormField(
                      controller: dob,
                      readOnly: true,
                      onTap: pickDOB,
                      decoration: _dec("Date of Birth"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),

                    TextFormField(
                      controller: mother,
                      decoration: _dec("Mother Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),

                    TextFormField(
                      controller: cnic,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                        _CnicFormatter(),
                      ],
                      decoration: _dec("CNIC (xxxxx-xxxxxxx-x)"),
                    ),

                    TextFormField(
                      controller: address,
                      decoration: _dec("Address"),
                    ),

                    DropdownButtonFormField<String>(
                      value: gender.isEmpty ? null : gender,
                      items: ["Male", "Female", "Other"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => gender = v!),
                      decoration: _dec("Gender"),
                    ),

                    TextFormField(
                      controller: district,
                      decoration: _dec("District"),
                    ),

                    TextFormField(
                      controller: contactNumber,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        _PhoneFormatter(),
                      ],
                      decoration: _dec("03XX-XXXXXXX"),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: saveChild,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Save Child"),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ---------------- CNIC FORMAT ----------------
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

// ---------------- PHONE FORMAT ----------------
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll('-', '');

    if (digits.length > 4) {
      return TextEditingValue(
        text: "${digits.substring(0, 4)}-${digits.substring(4)}",
        selection: TextSelection.collapsed(offset: digits.length + 1),
      );
    }

    return newValue;
  }
}