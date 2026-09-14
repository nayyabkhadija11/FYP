/*import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, size: 60, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'Immuno', style: TextStyle(color: Color(0xFF064E3B))),
                        TextSpan(text: 'Sphere', style: TextStyle(color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI Powered Immunization\nand Vaccination Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}  */
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color midGreen = Color(0xFF0E7A45);
  static const Color accentGreen = Color(0xFF19A85B);
  static const Color taglineGrey = Color(0xFF9AA5A0);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------- LAYER A: top-left decorative green wave ----------
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              size: Size(size.width * 0.6, size.height * 0.24),
              painter: _TopLeftWavePainter(darkGreen: darkGreen, midGreen: midGreen),
            ),
          ),

          // ---------- LAYER B: baby-vaccine photo ----------
          // Chhoti, sirf bottom-left corner mein, aur poori tarah radial-fade
          // (har taraf se — upar, dayen, sab jagah se dheere dheere ghulti
          // hui) taake ye kabhi text/icons ke upar hard block ban ke na aaye.
          Positioned(
            bottom: 0,
            left: 0,
            child: SizedBox(
              width: size.width * 0.58,
              height: size.height * 0.26,
              child: ShaderMask(
                shaderCallback: (bounds) => const RadialGradient(
                  center: Alignment(-1.0, 1.0),
                  radius: 1.6,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.4, 0.9],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(darkGreen.withOpacity(0.18), BlendMode.color),
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      'assets/baby_vaccine.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('🔴 baby_vaccine.jpg load nahi ho saka: $error');
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---------- LAYER C + D: bottom green wave + faint watermark ----------
          // (photo ke UPAR draw hoti hai, is liye photo ka neecha hissa
          // naturally isi green ke neeche chala jata hai — koi seam nahi.)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: size.height * 0.24,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: -10,
                    right: -30,
                    child: Opacity(
                      opacity: 0.07,
                      child: Icon(Icons.shield_rounded, size: 140, color: Colors.white),
                    ),
                  ),
                  CustomPaint(
                    size: Size(size.width, size.height * 0.24),
                    painter: _BottomWavePainter(darkGreen: darkGreen, midGreen: midGreen),
                  ),
                ],
              ),
            ),
          ),

          // ---------- FOREGROUND CONTENT ----------
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // LOGO
                _buildLogo(),
                const SizedBox(height: 18),

                // APP NAME
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    children: [
                      TextSpan(text: 'Immuno', style: TextStyle(color: darkGreen)),
                      TextSpan(text: 'Sphere', style: TextStyle(color: accentGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI Powered Immunization\nand Vaccination Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: darkGreen, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 10),
                Container(width: 46, height: 3, decoration: BoxDecoration(color: accentGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                const Text(
                  'Healthier Children  |  Safer Communities\nA Stronger Tomorrow',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: taglineGrey, fontSize: 11.5, height: 1.4),
                ),

                const Spacer(flex: 2),

                // FEATURE HIGHLIGHTS ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _featureItem(Icons.vaccines_outlined, 'Vaccination\nTracking')),
                        const _VerticalDot(),
                        Expanded(child: _featureItem(Icons.hub_outlined, 'AI Risk\nPrediction')),
                        const _VerticalDot(),
                        Expanded(child: _featureItem(Icons.health_and_safety_outlined, 'Disease\nSurveillance')),
                        const _VerticalDot(),
                        Expanded(child: _featureItem(Icons.groups_outlined, 'Healthier\nCommunities')),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // LOADING
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
                const SizedBox(height: 10),
                const Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Solid dark-green shield, family silhouette white andar, orbit ring
  // poora girda hua, aur plus badge top-right corner par shield se
  // overlap karta hai.
  Widget _buildLogo() {
    const double size = 112;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Full orbit ring around the shield — thicker stroke
          CustomPaint(
            size: const Size(size, size),
            painter: _FullOrbitRingPainter(color: accentGreen),
          ),
          // Halka circular backdrop taake shield aur ring ke darmiyan
          // thora "breathing space" nazar aaye (badge jaisa look)
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          // Shield: subtle gradient fill (professional look, flat color nahi)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [darkGreen, midGreen],
            ).createShader(bounds),
            child: const Icon(Icons.shield, size: 66, color: Colors.white),
          ),
          // Mother + child silhouette (white, inside shield)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.escalator_warning_rounded, size: 29, color: Colors.white),
          ),
          // Plus badge, top-right, ring ke gap wale sirey par
          const Positioned(
            top: 8,
            right: 4,
            child: _PlusBadge(),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFEAF6EE), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: midGreen),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: darkGreen, fontWeight: FontWeight.w600, height: 1.2),
        ),
      ],
    );
  }
}

class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF19A85B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: const Icon(Icons.add, size: 13, color: Colors.white),
    );
  }
}

class _VerticalDot extends StatelessWidget {
  const _VerticalDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.only(top: 18),
      color: Colors.grey.shade300,
    );
  }
}

class _FullOrbitRingPainter extends CustomPainter {
  final Color color;
  _FullOrbitRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.92,
      height: size.height * 0.7,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, 0.55, 5.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopLeftWavePainter extends CustomPainter {
  final Color darkGreen;
  final Color midGreen;
  _TopLeftWavePainter({required this.darkGreen, required this.midGreen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkGreen, midGreen],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.78, 0)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.58, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.9, 0, size.height * 0.6)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  final Color darkGreen;
  final Color midGreen;
  _BottomWavePainter({required this.darkGreen, required this.midGreen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [midGreen, darkGreen],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.05, size.width * 0.5, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.4, size.width, size.height * 0.12)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}