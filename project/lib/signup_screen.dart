/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> signup() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // ICON
                const Icon(
                  Icons.person_add_alt_1,
                  size: 90,
                  color: Colors.deepPurple,
                ),

                const SizedBox(height: 20),

                // TITLE
                const Text(
                  "Signup",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 30),

                // EMAIL FIELD
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // PASSWORD FIELD
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> signup() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ImmunoSphere Theme Colors
    const Color primaryBlue = Color(0xFF1954A6);
    const Color lightBg = Color(0xFFF3F9FF);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // --- LOGO SECTION (Based on ImmunoSphere Theme) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined, // Matching logo icon
                    size: 80,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "ImmunoSphere",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                  ),
                ),
                const Text(
                  "Join our management system",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // --- INPUT FIELDS ---
                // EMAIL FIELD
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined, color: primaryBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // PASSWORD FIELD
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // --- BACK TO LOGIN ---
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  // ✅ ROLE ADDED
  String selectedRole = "user";

  Future<void> signup() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // ✅ SAVE ROLE WITH EMAIL & PASSWORD USER
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "email": email.text.trim(),
        "role": selectedRole,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ImmunoSphere Theme Colors
    const Color primaryBlue = Color(0xFF1954A6);
    const Color lightBg = Color(0xFFF3F9FF);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "ImmunoSphere",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                  ),
                ),
                const Text(
                  "Join our management system",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // EMAIL
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: primaryBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // PASSWORD
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: primaryBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ✅ ROLE DROPDOWN (ONLY ADDITION)
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: "user", child: Text("User")),
                    DropdownMenuItem(value: "admin", child: Text("Admin")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Role",
                    prefixIcon:
                        const Icon(Icons.person, color: primaryBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/
/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import karein

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  
  // Role selection state
  String selectedRole = 'Parent'; 
  final List<String> roles = ['Vaccinator', 'Supervisor', 'Parent', 'Finance Officer'];

  bool isLoading = false;

  Future<void> signup() async {
    setState(() => isLoading = true);
    try {
      // 1. Firebase Auth User Create Karein
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // 2. User ka role Firestore mein save karein
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email.text.trim(),
        'role': selectedRole,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created! Please Login.")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1954A6);
    const Color lightBg = Color(0xFFF3F9FF);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                child: const Icon(Icons.shield_outlined, size: 60, color: primaryBlue),
              ),
              const SizedBox(height: 20),
              const Text("ImmunoSphere", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryBlue)),
              const SizedBox(height: 30),
              
              // Email
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email_outlined, color: primaryBlue), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 15),

              // Password
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 15),

              // --- ROLE DROPDOWN ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
                    items: roles.map((String role) {
                      return DropdownMenuItem(value: role, child: Text("Register as: $role"));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedRole = value!),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Already have an account? Login", style: TextStyle(color: primaryBlue))),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final fullName = TextEditingController(); // Name controller add kiya
  final email = TextEditingController();
  final password = TextEditingController();
  
  // Role selection state (Initial value null rakhi hai placeholder ke liye)
  String? selectedRole; 
  final List<String> roles = ['Vaccinator', 'Supervisor', 'Parent', 'Finance Officer'];

  bool isLoading = false;

  Future<void> signup() async {
    // Validation check
    if (fullName.text.isEmpty || email.text.isEmpty || password.text.isEmpty || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a role")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // 1. Firebase Auth User Create Karein
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // 2. User ka data (Name + Role) Firestore mein save karein
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': fullName.text.trim(),
        'email': email.text.trim(),
        'role': selectedRole,
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created! Please Login."))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()))
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1954A6);
    const Color lightBg = Color(0xFFF3F9FF);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]
                ),
                child: const Icon(Icons.person_add_alt_1_outlined, size: 60, color: primaryBlue),
              ),
              const SizedBox(height: 20),
              const Text("ImmunoSphere", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryBlue)),
              const SizedBox(height: 30),
              
              // Full Name Field
              TextField(
                controller: fullName,
                decoration: InputDecoration(
                  labelText: "Full Name", 
                  prefixIcon: const Icon(Icons.person_outline, color: primaryBlue), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),

              // Email Field
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email", 
                  prefixIcon: const Icon(Icons.email_outlined, color: primaryBlue), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password", 
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),

              // --- ROLE DROPDOWN ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    hint: const Text("Select a Role"), // Placeholder text
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
                    items: roles.map((String role) {
                      return DropdownMenuItem(
                        value: role, 
                        child: Text(role) // Role list item mein show hoga
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedRole = value),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Signup Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Already have an account? Login", style: TextStyle(color: primaryBlue))
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  
  String? selectedRole; 
  final List<String> roles = ['Vaccinator', 'Supervisor', 'Parent', 'Finance Officer'];

  bool isLoading = false;

  // 🔥 Email Validation Function
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> signup() async {
    String nameTxt = fullName.text.trim();
    String emailTxt = email.text.trim();
    String passTxt = password.text.trim();

    // 1. Basic Empty Check
    if (nameTxt.isEmpty || emailTxt.isEmpty || passTxt.isEmpty || selectedRole == null) {
      showError("Please fill all fields and select a role");
      return;
    }

    // 2. Email Format Validation
    if (!isValidEmail(emailTxt)) {
      showError("Please enter a valid email address");
      return;
    }

    // 3. Password Length Validation
    if (passTxt.length < 6) {
      showError("Password must be at least 6 characters long");
      return;
    }

    setState(() => isLoading = true);
    try {
      // 1. Firebase Auth User Create Karein
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTxt,
        password: passTxt,
      );

      // 2. User ka data Firestore mein save karein
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': nameTxt,
        'email': emailTxt,
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(), // Better for sorting
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created Successfully!"))
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Firebase specific errors (like email already in use)
      showError(e.message ?? "An error occurred");
    } catch (e) {
      showError(e.toString());
    }
    setState(() => isLoading = false);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1954A6);
    const Color lightBg = Color(0xFFF3F9FF);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]
                ),
                child: const Icon(Icons.person_add_alt_1_outlined, size: 60, color: primaryBlue),
              ),
              const SizedBox(height: 20),
              const Text("ImmunoSphere", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryBlue)),
              const SizedBox(height: 30),
              
              TextField(
                controller: fullName,
                decoration: InputDecoration(
                  labelText: "Full Name", 
                  prefixIcon: const Icon(Icons.person_outline, color: primaryBlue), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email", 
                  prefixIcon: const Icon(Icons.email_outlined, color: primaryBlue), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password", 
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    hint: const Text("Select a Role"),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
                    items: roles.map((String role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedRole = value),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Already have an account? Login", style: TextStyle(color: primaryBlue))
              ),
            ],
          ),
        ),
      ),
    );
  }
}