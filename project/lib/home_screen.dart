/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentUser = "";

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUser = prefs.getString("currentUser") ?? "Unknown User";
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("isLoggedIn");
    await prefs.remove("currentUser");

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void selectRole(String role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Selected Role: $role")),
    );
  }

  Widget roleCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => selectRole(title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 👤 USER INFO
            Text(
              "Logged in as:",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              currentUser,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // 🎯 ROLE GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [

                  roleCard("Admin", Icons.admin_panel_settings, Colors.red),

                  roleCard("Vaccinator", Icons.medical_services, Colors.blue),

                  roleCard("User", Icons.person, Colors.green),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey/blue background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // --- Header Section ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "project",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0891B2), // Teal color from image
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "AI-Powered Immunization & Vaccination Management Portal",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
              const Text(
                "Protecting Pakistan's Children, One Dose at a Time",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 40),

              // --- Roles Grid ---
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoleCard(
                    context,
                    title: "Vaccinator",
                    desc: "Record vaccinations in the field",
                    icon: Icons.show_chart,
                    iconColor: const Color(0xFF3B82F6),
                    route: '/vaccinator_screen',
                  ),
                  _buildRoleCard(
                    context,
                    title: "Supervisor",
                    desc: "Monitor campaigns and coverage",
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF22C55E),
                    route: '/supervisor_dashboard',
                  ),
                  _buildRoleCard(
                    context,
                    title: "Parent",
                    desc: "Track your child's vaccinations",
                    icon: Icons.child_care,
                    iconColor: const Color(0xFFA855F7),
                    route: '/parent_screen',
                  ),
                  _buildRoleCard(
                    context,
                    title: "Finance Officer",
                    desc: "Manage payments and salaries",
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFFF97316),
                    route: '/finance_dashboard',
                  ),
                  _buildRoleCard(
                    context,
                    title: "AI Analytics",
                    desc: "View predictions and insights",
                    icon: Icons.psychology_outlined,
                    iconColor: const Color(0xFFEF4444),
                    route: '/analytics_dashboard',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 300, // Fixed width to match the card style
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}*/
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ImmunoSphere Theme Colors
    const Color primaryBlue = Color(0xFF1954A6);
    const Color lightBg = Color(0xFFF3F9FF);

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // --- Header Section (ImmunoSphere Branding) ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: primaryBlue,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ImmunoSphere",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "AI-Powered Immunization Management Portal",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF475569), 
                  fontSize: 16,
                  fontWeight: FontWeight.w500
                ),
              ),
              const Text(
                "Protecting Pakistan's Children, One Dose at a Time",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 40),

              // --- Roles Grid ---
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoleCard(
                    context,
                    title: "Vaccinator",
                    desc: "Record vaccinations in the field",
                    icon: Icons.biotech_outlined,
                    iconColor: primaryBlue,
                    route: '/vaccinator_screen',
                  ),
                  _buildRoleCard(
                    context,
                    title: "Supervisor",
                    desc: "Monitor campaigns and coverage",
                    icon: Icons.admin_panel_settings_outlined,
                    iconColor: const Color(0xFF059669), // Emerald Green
                    route: '/supervisor_screen',
                  ),
                  _buildRoleCard(
                    context,
                    title: "Parent",
                    desc: "Track your child's vaccinations",
                    icon: Icons.family_restroom_outlined,
                    iconColor: const Color(0xFF7C3AED), // Soft Purple
                    route: '/parent_screen',
                  ),
                  _buildRoleCard(
                    context,
                    title: "Finance Officer",
                    desc: "Manage payments and salaries",
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFFD97706), // Amber
                    route: '/finance_screen',
                  ),
                  _buildRoleCard(
                    context,
                    title: "AI Analytics",
                    desc: "View predictions and insights",
                    icon: Icons.insights_outlined,
                    iconColor: const Color(0xFFDC2626), // Soft Red
                    route: '/analytics_dashboard',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 280, // Slightly adjusted for better fit
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF0F172A)
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 14, 
                color: Color(0xFF64748B),
                height: 1.4
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Text(
                  "Get Started",
                  style: TextStyle(
                    color: Color(0xFF1954A6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Color(0xFF1954A6)),
              ],
            )
          ],
        ),
      ),
    );
  }
}