import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ChamCongApp());

const bg = Color(0xFF071120);
const panel = Color(0xFF0D1A2D);
const blue = Color(0xFF2388FF);
const green = Color(0xFF19B779);
const muted = Color(0xFF91A7C9);

class ChamCongApp extends StatelessWidget {
  const ChamCongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm Công',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: blue, surface: panel),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const AttendancePage(),
    );
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime shownMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime today = DateTime.now();
  final Set<String> workedDays = {};
  final TextEditingController salaryController = TextEditingController();
  int salaryPerDay = 300000;
  bool loaded = false;

  String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    salaryController.text = _money(salaryPerDay);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('worked_days') ?? [];
    final salary = prefs.getInt('salary_per_day') ?? 300000;
    if (!mounted) return;
    setState(() {
      workedDays
        ..clear()
        ..addAll(saved);
      salaryPerDay = salary;
      salaryController.text = _money(salary);
      loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('worked_days', workedDays.toList());
    await prefs.setInt('salary_per_day', salaryPerDay);
  }

  String _money(int value) {
    final s = value.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      out.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) out.write('.');
    }
    return out.toString();
  }

  int get workedThisMonth =>
      workedDays.where((s) => s.startsWith(monthKey(shownMonth))).length;
  int get totalSalary => workedThisMonth * salaryPerDay;

  void _changeMonth(int delta) {
    setState(() {
      shownMonth = DateTime(shownMonth.year, shownMonth.month + delta);
    });
  }

  Future<void> _toggleDay(DateTime date) async {
    final key = keyFor(date);
    setState(() {
      if (workedDays.contains(key)) {
        workedDays.remove(key);
      } else {
        workedDays.add(key);
      }
    });
    await _save();
  }

  Future<void> _saveSalary() async {
    final raw = salaryController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bro nhập mức lương hợp lệ nhé.')),
      );
      return;
    }
    setState(() => salaryPerDay = parsed);
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu lương một ngày.')),
    );
  }

  @override
  void dispose() {
    salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(shownMonth.year, shownMonth.month, 1);
    final daysInMonth = DateTime(shownMonth.year, shownMonth.month + 1, 0).day;
    // Monday = column 0, Sunday = column 6.
    final offset = firstDay.weekday - 1;
    final cellCount = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final monthTitle = '${shownMonth.month.toString().padLeft(2, '0')} / ${shownMonth.year}';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.calendar_month_rounded, size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Chấm Công', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                          SizedBox(height: 3),
                          Text('Quản lý ngày công · Tính lương', style: TextStyle(color: muted, fontSize: 13)),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Cài đặt',
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SalarySettingsPage(
                              initialSalary: salaryPerDay,
                              onSave: (value) async {
                                setState(() => salaryPerDay = value);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setInt('salary_per_day', value);
                              },
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.settings_rounded, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1B3559)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 9,
                          child: Column(children: [
                            const Icon(Icons.calendar_month, color: blue, size: 22),
                            const SizedBox(height: 6),
                            const Text('Tháng / Năm', style: TextStyle(color: muted, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _changeMonth(-1),
                                icon: const Icon(Icons.chevron_left, color: muted, size: 28),
                              ),
                              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(monthTitle,
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _changeMonth(1),
                                icon: const Icon(Icons.chevron_right, color: muted, size: 28),
                              ),
                            ]),
                          ]),
                        ),
                        Container(width: 1, height: 82, color: const Color(0xFF263955)),
                        Expanded(
                          flex: 7,
                          child: Column(children: [
                            const Icon(Icons.check_circle, color: green, size: 22),
                            const SizedBox(height: 6),
                            const Text('Số ngày công', style: TextStyle(color: muted, fontSize: 12)),
                            const SizedBox(height: 10),
                            Text('$workedThisMonth ngày', style: const TextStyle(
                              color: Color(0xFF35D9A0), fontSize: 20, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        Container(width: 1, height: 82, color: const Color(0xFF263955)),
                        Expanded(
                          flex: 8,
                          child: Column(children: [
                            const Icon(Icons.payments_rounded, color: Color(0xFFFFC44D), size: 22),
                            const SizedBox(height: 6),
                            const Text('Tiền lương', style: TextStyle(color: muted, fontSize: 12)),
                            const SizedBox(height: 10),
                            FittedBox(fit: BoxFit.scaleDown, child: Text('${_money(totalSalary)}đ',
                              style: const TextStyle(color: Color(0xFFFFC44D), fontSize: 19, fontWeight: FontWeight.w800))),
                            const SizedBox(height: 3),
                            FittedBox(fit: BoxFit.scaleDown, child: Text('(${_money(salaryPerDay)} × $workedThisMonth)',
                              style: const TextStyle(color: muted, fontSize: 10))),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF182B47)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'
                          ].map((s) => Expanded(child: Center(child: Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(s, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                          )))).toList(),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cellCount,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7, crossAxisSpacing: 5, mainAxisSpacing: 6, childAspectRatio: 0.82),
                          itemBuilder: (context, index) {
                            final dayNum = index - offset + 1;
                            if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();
                            final date = DateTime(shownMonth.year, shownMonth.month, dayNum);
                            final isWorked = workedDays.contains(keyFor(date));
                            final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                            final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
                            return Material(
                              color: isWorked ? green.withOpacity(0.20) : const Color(0xFF111F33),
                              borderRadius: BorderRadius.circular(11),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () => _toggleDay(date),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: isToday ? blue : (isWorked ? green.withOpacity(0.8) : const Color(0xFF1D2B40)),
                                      width: isToday ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 31, height: 31,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isWorked ? green : (isFuture ? const Color(0xFF0A1424) : const Color(0xFF263752)),
                                      ),
                                      child: Center(child: Text('$dayNum', style: TextStyle(
                                        color: isWorked ? Colors.white : (isFuture ? const Color(0xFF60718C) : Colors.white),
                                        fontSize: 13, fontWeight: FontWeight.w700))),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        const Wrap(
                          spacing: 14, runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _Legend(color: green, text: 'Đã chấm công'),
                            _Legend(color: Color(0xFF263752), text: 'Chưa chấm'),
                            _Legend(color: blue, text: 'Hôm nay'),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Text('Chạm vào ngày để bật/tắt ngày công', style: TextStyle(color: muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('Chạm vào ngày để bật/tắt ngày công', style: TextStyle(color: Color(0xFF6E829F), fontSize: 11))),
                  const Center(child: Text('Dữ liệu được lưu trên thiết bị này', style: TextStyle(color: Color(0xFF6E829F), fontSize: 11))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SalarySettingsPage extends StatefulWidget {
  final int initialSalary;
  final Future<void> Function(int value) onSave;

  const SalarySettingsPage({
    super.key,
    required this.initialSalary,
    required this.onSave,
  });

  @override
  State<SalarySettingsPage> createState() => _SalarySettingsPageState();
}

class _SalarySettingsPageState extends State<SalarySettingsPage> {
  late final TextEditingController controller;
  bool saving = false;

  String formatMoney(int value) {
    final s = value.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      out.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) out.write('.');
    }
    return out.toString();
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: formatMoney(widget.initialSalary));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final raw = controller.text.replaceAll('.', '').replaceAll(',', '').trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bro nhập mức lương hợp lệ nhé.')),
      );
      return;
    }
    setState(() => saving = true);
    await widget.onSave(parsed);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu lương một ngày.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1B3559)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.payments_rounded, color: Color(0xFFFFC44D), size: 25),
                  SizedBox(width: 10),
                  Text('Lương một ngày', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Nhập mức lương cho một ngày công. App sẽ tự tính tổng lương theo số ngày đã tích trên lịch.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Lương / ngày',
                    prefixText: 'đ  ',
                    hintText: '300.000',
                    filled: true,
                    fillColor: const Color(0xFF101F34),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  onSubmitted: (_) => save(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(saving ? 'Đang lưu...' : 'Lưu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(text, style: const TextStyle(color: muted, fontSize: 10)),
  ]);
}
