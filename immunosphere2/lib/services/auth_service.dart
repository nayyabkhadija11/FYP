/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'email_validator_service.dart'; // <--- 1. Service import kar di hai

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Currently logged in user getter
  User? get currentUser => _auth.currentUser;

  // 1. User Registration Method (With Live Email & Employee ID Verification)
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? employeeId,
    String? supervisorId,
  }) async {
    try {
      String finalEmpId = (employeeId ?? supervisorId ?? '').trim();

      // STEP A: Validate Employee / Supervisor ID from Firestore
      if (role == 'Vaccinator' || role == 'Supervisor') {
        if (finalEmpId.isEmpty) {
          return "Please enter your $role ID.";
        }

        // Check ID in valid_employees collection
        DocumentSnapshot empDoc = await _firestore
            .collection('valid_employees')
            .doc(finalEmpId)
            .get();

        if (!empDoc.exists) {
          return "Invalid $role ID! Please contact administration.";
        }

        Map<String, dynamic> empData = empDoc.data() as Map<String, dynamic>;

        if (empData['role'] != role) {
          return "This ID is not assigned to a $role.";
        }

        if (empData['isUsed'] == true) {
          return "This $role ID has already been registered.";
        }
      }

      // STEP B: LIVE EMAIL EXISTENCE CHECK (Before Firebase Account Creation)
      bool isValidEmail = await EmailValidatorService.isEmailValidAndActive(email.trim());

      if (!isValidEmail) {
        return "This Gmail address does not exist! Please enter a valid, active Gmail account.";
      }

      // STEP C: Create User in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send Verification Email safely
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint("Verification email error: $e");
        }

        // STEP D: Prepare User Data
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'isApproved': role == 'Parent' ? true : false,
        };

        if (employeeId != null) userData['employeeId'] = employeeId.trim();
        if (supervisorId != null) userData['supervisorId'] = supervisorId.trim();

        // Save User Details to Firestore ('users' collection)
        await _firestore.collection('users').doc(user.uid).set(userData);

        // STEP E: Mark Employee ID as Used in 'valid_employees'
        if (role == 'Vaccinator' || role == 'Supervisor') {
          await _firestore
              .collection('valid_employees')
              .doc(finalEmpId)
              .update({'isUsed': true});
        }

        return null; // Return null = Success
      }
      return "User creation failed. Please try again.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "This email address is already registered. Please log in or use a different email.";
      } else if (e.code == 'invalid-email') {
        return "The email address entered is invalid.";
      } else if (e.code == 'weak-password') {
        return "The password is too weak. Please enter at least 6 characters.";
      } else if (e.code == 'too-many-requests') {
        return "Too many attempts. Please wait a few minutes before trying again.";
      }
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Login Method with Strict Verification Check
  Future<String?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        await _auth.signOut(); 
        return "Email not verified! Please check your Gmail Inbox/Spam folder and click the verification link.";
      }

      return null; // Return null = Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No account found with this email address.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        return "Please enter a valid email address.";
      } else if (e.code == 'too-many-requests') {
        return "Access to this account has been temporarily disabled due to many failed attempts. Try again later.";
      }
      return e.message ?? "Login failed. Please check your credentials.";
    } catch (e) {
      return e.toString();
    }
  }

  // 3. Separate Resend Verification Link Method
  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null;
      }
      return "No unverified user found.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return "Please wait a few minutes before requesting another email.";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 4. Password Reset Email Method
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Return null = Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No user found with this email address.";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format. Please check the address.";
      }
      return e.message ?? "Failed to send password reset email.";
    } catch (e) {
      return e.toString();
    }
  }

  // 5. Sign Out Method
  Future<void> signOut() async {
    await _auth.signOut();
  }
} */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'email_validator_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Currently logged in user getter
  User? get currentUser => _auth.currentUser;

  // 1. User Registration Method (With Live Email & Employee ID Verification + CNIC Support)
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? cnic, // <--- ADDED: CNIC parameter optional/required
    String? employeeId,
    String? supervisorId,
  }) async {
    try {
      String finalEmpId = (employeeId ?? supervisorId ?? '').trim();

      // STEP A: Validate Employee / Supervisor ID from Firestore
      if (role == 'Vaccinator' || role == 'Supervisor') {
        if (finalEmpId.isEmpty) {
          return "Please enter your $role ID.";
        }

        // Check ID in valid_employees collection
        DocumentSnapshot empDoc = await _firestore
            .collection('valid_employees')
            .doc(finalEmpId)
            .get();

        if (!empDoc.exists) {
          return "Invalid $role ID! Please contact administration.";
        }

        Map<String, dynamic> empData = empDoc.data() as Map<String, dynamic>;

        if (empData['role'] != role) {
          return "This ID is not assigned to a $role.";
        }

        if (empData['isUsed'] == true) {
          return "This $role ID has already been registered.";
        }
      }

      // STEP B: LIVE EMAIL EXISTENCE CHECK (Before Firebase Account Creation)
      bool isValidEmail = await EmailValidatorService.isEmailValidAndActive(email.trim());

      if (!isValidEmail) {
        return "This Gmail address does not exist! Please enter a valid, active Gmail account.";
      }

      // STEP C: Create User in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send Verification Email safely
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint("Verification email error: $e");
        }

        // STEP D: Prepare User Data
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'fullName': fullName.trim(),
          'name': fullName.trim(), // UI standard display field
          'email': email.trim(),
          'phone': phone.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'isApproved': role == 'Parent' ? true : false,
        };

        // Add CNIC if provided (crucial for Parents)
        if (cnic != null && cnic.trim().isNotEmpty) {
          userData['cnic'] = cnic.trim();
        }

        if (employeeId != null) userData['employeeId'] = employeeId.trim();
        if (supervisorId != null) userData['supervisorId'] = supervisorId.trim();

        // Save User Details to Firestore ('users' collection)
        await _firestore.collection('users').doc(user.uid).set(userData);

        // STEP E: Mark Employee ID as Used in 'valid_employees'
        if (role == 'Vaccinator' || role == 'Supervisor') {
          await _firestore
              .collection('valid_employees')
              .doc(finalEmpId)
              .update({'isUsed': true});
        }

        return null; // Return null = Success
      }
      return "User creation failed. Please try again.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "This email address is already registered. Please log in or use a different email.";
      } else if (e.code == 'invalid-email') {
        return "The email address entered is invalid.";
      } else if (e.code == 'weak-password') {
        return "The password is too weak. Please enter at least 6 characters.";
      } else if (e.code == 'too-many-requests') {
        return "Too many attempts. Please wait a few minutes before trying again.";
      }
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Login Method with Strict Verification Check
  Future<String?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        await _auth.signOut(); 
        return "Email not verified! Please check your Gmail Inbox/Spam folder and click the verification link.";
      }

      return null; // Return null = Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No account found with this email address.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        return "Please enter a valid email address.";
      } else if (e.code == 'too-many-requests') {
        return "Access to this account has been temporarily disabled due to many failed attempts. Try again later.";
      }
      return e.message ?? "Login failed. Please check your credentials.";
    } catch (e) {
      return e.toString();
    }
  }

  // 3. Separate Resend Verification Link Method
  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null;
      }
      return "No unverified user found.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return "Please wait a few minutes before requesting another email.";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 4. Password Reset Email Method
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Return null = Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No user found with this email address.";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format. Please check the address.";
      }
      return e.message ?? "Failed to send password reset email.";
    } catch (e) {
      return e.toString();
    }
  }

  // 5. Sign Out Method
  Future<void> signOut() async {
    await _auth.signOut();
  }
}