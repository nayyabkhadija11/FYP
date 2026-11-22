/*import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/ai_insights_service.dart';
import 'create_campaign_screen.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  // ---- Theme ----
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color accent = Color(0xFF0E7A45);
  static const Color barGreen = Color(0xFF1DA25B);
  static const Color warnOrange = Color(0xFFF5A623);
  static const Color riskRed = Color(0xFFE53935);
  static const Color bgColor = Color(0xFFF4F7F5);

  final AiInsightsService _service = AiInsightsService();

  String _tab = 'routine'; // 'routine' | 'polio'
  Future<InsightsResult>? _routineF;
  Future<InsightsResult>? _polioF;

  Future<InsightsResult> _futureFor(String tab) {
    if (tab == 'polio') {
      return _polioF ??= _service.loadPolio();
    }
    return _routineF ??= _service.loadRoutine();
  }

  void _reload() {
    setState(() {
      if (_tab == 'polio') {
        _polioF = _service.loadPolio();
      } else {
        _routineF = _service.loadRoutine();
      }
    });
  }

  // =================================================================
  // BUILD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                _pill('Routine', Icons.vaccines_outlined, 'routine'),
                const SizedBox(width: 10),
                _pill('Polio', Icons.water_drop_outlined, 'polio'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<InsightsResult>(
              future: _futureFor(_tab),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: accent));
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Data load nahi ho saka:\n${snap.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: riskRed, fontSize: 12)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _reload,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                foregroundColor: Colors.white),
                            child: const Text('Dobara koshish karein'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _content(snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // HEADER + PILLS
  // =================================================================
  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'AI Insights',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Smarter Decisions. Healthier Community.',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: _reload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, IconData icon, String key) {
    final sel = _tab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? darkGreen : const Color(0xFFE3F1E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: sel ? Colors.white : darkGreen),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : darkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================================================================
  // CONTENT
  // =================================================================
  Widget _content(InsightsResult r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      child: Column(
        children: [
          _statCards(r),
          const SizedBox(height: 12),
          _coverageCard(r),
          const SizedBox(height: 12),
          _alertCard(r),
          const SizedBox(height: 12),
          _childrenCard(r),
          const SizedBox(height: 12),
          _recommendationCard(r),
          const SizedBox(height: 10),
          _footerNote(r),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? color, Color? border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border != null ? Border.all(color: border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ---------------- stat cards ----------------
  Widget _statCards(InsightsResult r) {
    String sub = '';
    if (r.coverageChange != null) {
      final c = r.coverageChange!;
      sub = '(${c >= 0 ? '+' : ''}${c.toStringAsFixed(1)}%)';
    }
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.groups_2,
            value: '${r.highRiskCount}',
            label: 'High-Risk\nChildren',
            bg: const Color(0xFFE3F5EA),
            fg: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            icon: Icons.verified_user,
            value: '${r.coverage.round()}%',
            label: 'Coverage Rate',
            sub: sub,
            bg: const Color(0xFFE3F5EA),
            fg: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            icon: Icons.warning_rounded,
            value: '${r.areasAtRisk}',
            label: 'Areas at Risk',
            bg: const Color(0xFFFFE3E3),
            fg: riskRed,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    String sub = '',
    required Color bg,
    required Color fg,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Colors.black87, height: 1.15)),
          if (sub.isNotEmpty)
            Text(sub, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------- coverage chart ----------------
  Color _barColor(double pct) {
    if (pct >= AiConfig.coverageTarget) return barGreen;
    if (pct >= 75) return warnOrange;
    return riskRed;
  }

  Widget _coverageCard(InsightsResult r) {
    const double plotH = 150;
    const double axisW = 34;
    const yLabels = ['100%', '75%', '50%', '25%', '0%'];
    final areas = r.areas;

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: accent, size: 22),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Area-wise Coverage',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: darkGreen),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.5)),
                ),
                child: const Text('Till today',
                    style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (areas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text('Abhi coverage ka data nahi hai.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else ...[
            const SizedBox(height: 16),
            SizedBox(
              height: plotH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: axisW,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: yLabels
                          .map((l) => Text(l,
                              style: const TextStyle(fontSize: 9.5, color: Colors.black54)))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (_) => Container(height: 1, color: Colors.grey.shade200),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            children: areas.map((a) => Expanded(child: _bar(a, plotH))).toList(),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: plotH * AiConfig.coverageTarget / 100,
                          child: SizedBox(
                            height: 2,
                            child: CustomPaint(painter: _DashPainter()),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: plotH * AiConfig.coverageTarget / 100 + 3,
                          child: Text(
                            '${AiConfig.coverageTarget.round()}%',
                            style: const TextStyle(
                                fontSize: 10, color: barGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: axisW),
                ...areas.map(
                  (a) => Expanded(
                    child: Text(
                      a.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Dashed line = ${AiConfig.coverageTarget.round()}% target. Sirf sab se kam coverage wale areas dikhaye gaye hain.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(AreaStat a, double plotH) {
    final pct = math.min(100.0, math.max(0.0, a.coverage));
    final h = plotH * pct / 100;
    return SizedBox(
      height: plotH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: h,
            decoration: BoxDecoration(
              color: _barColor(a.coverage),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          Positioned(
            bottom: h + 2,
            child: Text(
              '${a.coverage.round()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- alert ----------------
  Widget _alertCard(InsightsResult r) {
    final bad = r.hasAlert;
    final color = bad ? riskRed : accent;
    return _card(
      color: bad ? const Color(0xFFFFE3E3) : const Color(0xFFE3F5EA),
      border: color.withOpacity(0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              bad
                  ? (r.kind == 'polio' ? Icons.water_drop : Icons.coronavirus_outlined)
                  : Icons.check_circle_outline,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bad ? r.alertTitle : 'No Risk Alert',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    if (bad)
                      InkWell(
                        onTap: () => _showSheet(
                          r.alertTitle,
                          r.alertDetails
                              .map((d) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on_outlined,
                                        color: riskRed, size: 20),
                                    title: Text(d, style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: riskRed.withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Text('View Details',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: riskRed,
                                      fontWeight: FontWeight.w600)),
                              Icon(Icons.chevron_right, size: 14, color: riskRed),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.alertText,
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- high-risk children ----------------
  Widget _childrenCard(InsightsResult r) {
    final top = r.children.take(3).toList();
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2, color: accent, size: 22),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'High-Risk Children List',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: darkGreen),
                ),
              ),
              if (r.children.length > 3)
                InkWell(
                  onTap: () => _showSheet(
                    'All Risk Children (${r.children.length})',
                    [_childrenTable(r.children)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Text('View All',
                            style: TextStyle(
                                fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right, size: 15, color: accent),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Koi bar bar miss ya refuse karne wala bacha nahi mila.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            _childrenTable(top),
        ],
      ),
    );
  }

  Widget _childrenTable(List<RiskChild> list) {
    const head = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: darkGreen);
    Widget cols(List<Widget> c, {Color? bg, bool border = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          border: border
              ? Border(top: BorderSide(color: Colors.grey.shade200))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: c[0]),
            Expanded(flex: 3, child: c[1]),
            Expanded(flex: 3, child: c[2]),
            Expanded(flex: 2, child: c[3]),
            Expanded(flex: 3, child: c[4]),
            Expanded(flex: 3, child: c[5]),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            cols(const [
              Text('Child ID', style: head),
              Text('Area', style: head),
              Text('Missed\nVaccine', style: head),
              Text('Missed\nDoses', style: head, textAlign: TextAlign.center),
              Text('Disease\nRisk', style: head),
              Text('Status', style: head, textAlign: TextAlign.center),
            ], bg: const Color(0xFFE3F5EA)),
            ...list.map((c) {
              final high = c.status == 'High Risk';
              const cell = TextStyle(fontSize: 10, color: Colors.black87);
              return cols([
                Text(c.displayId, style: cell),
                Text(c.area, style: cell),
                Text(c.missedVaccine, style: cell),
                Text('${c.missedDoses}', style: cell, textAlign: TextAlign.center),
                Text(c.disease, style: cell),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: high ? const Color(0xFFFFD6D6) : const Color(0xFFFFF0B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: high ? riskRed : const Color(0xFFB7791F),
                        ),
                      ),
                    ),
                    if (c.probability >= 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'AI ${(c.probability * 100).round()}%',
                          style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ], border: true);
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- recommendation ----------------
  Widget _recommendationCard(InsightsResult r) {
    final canCreate = r.hasAlert && r.recAreas.isNotEmpty;
    return _card(
      color: const Color(0xFFE3F5EA),
      border: accent.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accent, size: 22),
              SizedBox(width: 6),
              Text('AI Recommendation',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: darkGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  r.recommendation,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: canCreate ? () => _createCampaign(r) : null,
                icon: const Icon(Icons.campaign_outlined, size: 17),
                label: const Text('Create Campaign',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createCampaign(InsightsResult r) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final end = start.add(const Duration(days: 6));
    final areaText = r.recAreas.join(' & ');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCampaignScreen(
          initialName: r.recVaccine.isEmpty ? null : '${r.recVaccine} Catch-up - $areaText',
          initialType: r.campaignType,
          initialStartDate: start,
          initialEndDate: end,
          prefillAreas: r.recAreas,
          prefillChildIds: r.recChildIds,
          prefillVaccine: r.recVaccine.isEmpty ? null : r.recVaccine,
        ),
      ),
    );
  }

  // ---------------- footer ----------------
  Widget _footerNote(InsightsResult r) {
    String text;
    IconData icon;
    Color color;
    if (r.kind == 'polio') {
      text = 'Polio ka risk campaign ke asli records (Refused / Missed) se nikala gaya hai.';
      icon = Icons.info_outline;
      color = Colors.grey;
    } else if (r.aiOnline) {
      text = 'AI model (Random Forest) online hai. Risk % usi se aa raha hai.';
      icon = Icons.check_circle_outline;
      color = accent;
    } else {
      text = 'AI server band hai, isliye risk % rules se andaza kiya gaya hai. Server chalao aur Refresh dabao.';
      icon = Icons.warning_amber_rounded;
      color = warnOrange;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 10.5, color: color)),
        ),
      ],
    );
  }

  // ---------------- bottom sheet ----------------
  void _showSheet(String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen)),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dashed target line
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1DA25B)
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} */
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/ai_insights_service.dart';
import 'create_campaign_screen.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  // ---- Theme ----
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color accent = Color(0xFF0E7A45);
  static const Color barGreen = Color(0xFF1DA25B);
  static const Color warnOrange = Color(0xFFF5A623);
  static const Color riskRed = Color(0xFFE53935);
  static const Color bgColor = Color(0xFFF4F7F5);

  final AiInsightsService _service = AiInsightsService();

  String _tab = 'routine'; // 'routine' | 'polio'
  Future<InsightsResult>? _routineF;
  Future<InsightsResult>? _polioF;

  Future<InsightsResult> _futureFor(String tab) {
    if (tab == 'polio') {
      return _polioF ??= _service.loadPolio();
    }
    return _routineF ??= _service.loadRoutine();
  }

  void _reload() {
    setState(() {
      if (_tab == 'polio') {
        _polioF = _service.loadPolio();
      } else {
        _routineF = _service.loadRoutine();
      }
    });
  }

  // =================================================================
  // BUILD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                _pill('Routine', Icons.vaccines_outlined, 'routine'),
                const SizedBox(width: 10),
                _pill('Polio', Icons.water_drop_outlined, 'polio'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<InsightsResult>(
              future: _futureFor(_tab),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: accent));
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Data load nahi ho saka:\n${snap.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: riskRed, fontSize: 12)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _reload,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                foregroundColor: Colors.white),
                            child: const Text('Dobara koshish karein'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _content(snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // HEADER + PILLS
  // =================================================================
  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'AI Insights',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Smarter Decisions. Healthier Community.',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: _reload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, IconData icon, String key) {
    final sel = _tab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? darkGreen : const Color(0xFFE3F1E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: sel ? Colors.white : darkGreen),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : darkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================================================================
  // CONTENT
  // =================================================================
  Widget _content(InsightsResult r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      child: Column(
        children: [
          _statCards(r),
          const SizedBox(height: 12),
          _coverageCard(r),
          const SizedBox(height: 12),
          _alertCard(r),
          const SizedBox(height: 12),
          _childrenCard(r),
          const SizedBox(height: 12),
          _recommendationCard(r),
          const SizedBox(height: 10),
          _footerNote(r),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? color, Color? border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border != null ? Border.all(color: border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ---------------- stat cards ----------------
  Widget _statCards(InsightsResult r) {
    String sub = '';
    if (r.coverageChange != null) {
      final c = r.coverageChange!;
      sub = '(${c >= 0 ? '+' : ''}${c.toStringAsFixed(1)}%)';
    }
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.groups_2,
            value: '${r.highRiskCount}',
            label: 'High-Risk\nChildren',
            bg: const Color(0xFFE3F5EA),
            fg: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            icon: Icons.verified_user,
            value: '${r.coverage.round()}%',
            label: 'Coverage Rate',
            sub: sub,
            bg: const Color(0xFFE3F5EA),
            fg: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            icon: Icons.warning_rounded,
            value: '${r.areasAtRisk}',
            label: 'Areas at Risk',
            bg: const Color(0xFFFFE3E3),
            fg: riskRed,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    String sub = '',
    required Color bg,
    required Color fg,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Colors.black87, height: 1.15)),
          if (sub.isNotEmpty)
            Text(sub, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------- coverage chart ----------------
  Color _barColor(double pct) {
    if (pct >= AiConfig.coverageTarget) return barGreen;
    if (pct >= 75) return warnOrange;
    return riskRed;
  }

  Widget _coverageCard(InsightsResult r) {
    const double plotH = 150;
    const double axisW = 34;
    const yLabels = ['100%', '75%', '50%', '25%', '0%'];
    final areas = r.areas;

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: accent, size: 22),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Area-wise Coverage',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: darkGreen),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.5)),
                ),
                child: const Text('Till today',
                    style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (areas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text('Abhi coverage ka data nahi hai.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else ...[
            const SizedBox(height: 16),
            SizedBox(
              height: plotH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: axisW,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: yLabels
                          .map((l) => Text(l,
                              style: const TextStyle(fontSize: 9.5, color: Colors.black54)))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (_) => Container(height: 1, color: Colors.grey.shade200),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            children: areas.map((a) => Expanded(child: _bar(a, plotH))).toList(),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: plotH * AiConfig.coverageTarget / 100,
                          child: SizedBox(
                            height: 2,
                            child: CustomPaint(painter: _DashPainter()),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: plotH * AiConfig.coverageTarget / 100 + 3,
                          child: Text(
                            '${AiConfig.coverageTarget.round()}%',
                            style: const TextStyle(
                                fontSize: 10, color: barGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: axisW),
                ...areas.map(
                  (a) => Expanded(
                    child: Text(
                      a.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Dashed line = ${AiConfig.coverageTarget.round()}% target. Sirf sab se kam coverage wale areas dikhaye gaye hain.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(AreaStat a, double plotH) {
    final pct = math.min(100.0, math.max(0.0, a.coverage));
    final h = plotH * pct / 100;
    return SizedBox(
      height: plotH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: h,
            decoration: BoxDecoration(
              color: _barColor(a.coverage),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          Positioned(
            bottom: h + 2,
            child: Text(
              '${a.coverage.round()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- alert ----------------
  Widget _alertCard(InsightsResult r) {
    final bad = r.hasAlert;
    final color = bad ? riskRed : accent;
    return _card(
      color: bad ? const Color(0xFFFFE3E3) : const Color(0xFFE3F5EA),
      border: color.withOpacity(0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              bad
                  ? (r.kind == 'polio' ? Icons.water_drop : Icons.coronavirus_outlined)
                  : Icons.check_circle_outline,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bad ? r.alertTitle : 'No Risk Alert',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    if (bad)
                      InkWell(
                        onTap: () => _showSheet(
                          r.alertTitle,
                          r.alertDetails
                              .map((d) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on_outlined,
                                        color: riskRed, size: 20),
                                    title: Text(d, style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: riskRed.withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Text('View Details',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: riskRed,
                                      fontWeight: FontWeight.w600)),
                              Icon(Icons.chevron_right, size: 14, color: riskRed),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.alertText,
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- high-risk children ----------------
  Widget _childrenCard(InsightsResult r) {
    final top = r.children.take(3).toList();
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2, color: accent, size: 22),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'High-Risk Children List',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: darkGreen),
                ),
              ),
              if (r.children.length > 3)
                InkWell(
                  onTap: () => _showSheet(
                    'All Risk Children (${r.children.length})',
                    [_childrenTable(r.children)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Text('View All',
                            style: TextStyle(
                                fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right, size: 15, color: accent),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Koi bar bar miss ya refuse karne wala bacha nahi mila.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            _childrenTable(top),
        ],
      ),
    );
  }

  Widget _childrenTable(List<RiskChild> list) {
    const head = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: darkGreen);
    Widget cols(List<Widget> c, {Color? bg, bool border = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          border: border
              ? Border(top: BorderSide(color: Colors.grey.shade200))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 4, child: c[0]),
            Expanded(flex: 3, child: c[1]),
            Expanded(flex: 3, child: c[2]),
            Expanded(flex: 2, child: c[3]),
            Expanded(flex: 3, child: c[4]),
            Expanded(flex: 3, child: c[5]),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            cols(const [
              Text('Child', style: head),
              Text('Area', style: head),
              Text('Missed\nVaccine', style: head),
              Text('Missed\nDoses', style: head, textAlign: TextAlign.center),
              Text('Disease\nRisk', style: head),
              Text('Status', style: head, textAlign: TextAlign.center),
            ], bg: const Color(0xFFE3F5EA)),
            ...list.map((c) {
              final high = c.status == 'High Risk';
              const cell = TextStyle(fontSize: 10, color: Colors.black87);
              return cols([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    Text(c.displayId,
                        style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
                  ],
                ),
                Text(c.area, style: cell),
                Text(c.missedVaccine, style: cell),
                Text('${c.missedDoses}', style: cell, textAlign: TextAlign.center),
                Text(c.disease, style: cell),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: high ? const Color(0xFFFFD6D6) : const Color(0xFFFFF0B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: high ? riskRed : const Color(0xFFB7791F),
                        ),
                      ),
                    ),
                    if (c.probability >= 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'AI ${(c.probability * 100).round()}%',
                          style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ], border: true);
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- recommendation ----------------
  Widget _recommendationCard(InsightsResult r) {
    final canCreate = r.hasAlert && r.recAreas.isNotEmpty;
    return _card(
      color: const Color(0xFFE3F5EA),
      border: accent.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accent, size: 22),
              SizedBox(width: 6),
              Text('AI Recommendation',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: darkGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  r.recommendation,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: canCreate ? () => _createCampaign(r) : null,
                icon: const Icon(Icons.campaign_outlined, size: 17),
                label: const Text('Create Campaign',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createCampaign(InsightsResult r) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final end = start.add(const Duration(days: 6));
    final areaText = r.recAreas.join(' & ');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCampaignScreen(
          initialName: r.recVaccine.isEmpty ? null : '${r.recVaccine} Catch-up - $areaText',
          initialType: r.campaignType,
          initialStartDate: start,
          initialEndDate: end,
          prefillAreas: r.recAreas,
          prefillChildIds: r.recChildIds,
          prefillVaccine: r.recVaccine.isEmpty ? null : r.recVaccine,
        ),
      ),
    );
  }

  // ---------------- footer ----------------
  Widget _footerNote(InsightsResult r) {
    String text;
    IconData icon;
    Color color;
    if (r.kind == 'polio') {
      text = 'Polio ka risk campaign ke asli records (Refused / Missed) se nikala gaya hai.';
      icon = Icons.info_outline;
      color = Colors.grey;
    } else if (r.aiOnline) {
      text = 'AI model (Random Forest) online hai. Risk % usi se aa raha hai.';
      icon = Icons.check_circle_outline;
      color = accent;
    } else {
      text = 'AI server band hai, isliye risk % rules se andaza kiya gaya hai. Server chalao aur Refresh dabao.';
      icon = Icons.warning_amber_rounded;
      color = warnOrange;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 10.5, color: color)),
        ),
      ],
    );
  }

  // ---------------- bottom sheet ----------------
  void _showSheet(String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen)),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dashed target line
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1DA25B)
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}