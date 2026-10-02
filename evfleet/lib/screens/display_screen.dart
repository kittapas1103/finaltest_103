import 'package:flutter/material.dart';
import '../controllers/charger_controller.dart';
import '../models/app_user.dart';
import '../models/charger.dart';
import 'form_screen.dart';

class DisplayScreen extends StatefulWidget {
  final AppUser me;
  const DisplayScreen({super.key, required this.me});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  String? _filter; // null = ทั้งหมด

  void _msg(String t) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(t)));

  Future<void> _confirmDelete(Charger c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบสถานีชาร์จ'),
        content: Text('ต้องการลบ "${c.name}" ใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ')),
        ],
      ),
    );
    if (ok == true) {
      await ChargerController.delete(c.id);
      _msg('ลบ "${c.name}" แล้ว');
    }
  }

  void _edit(Charger c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            FormScreen(charger: c, onSaved: () => Navigator.pop(ctx)),
      ),
    );
  }

  Widget _summary(List<Charger> all) {
    final avail = all.where((c) => c.status == ChargerStatus.available).length;
    final charging =
        all.where((c) => c.status == ChargerStatus.charging).length;
    final power = all.fold<double>(0, (s, c) => s + c.powerKw);

    Widget box(String title, String value, IconData icon, Color color) {
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, color: color),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          box('ทั้งหมด', '${all.length}', Icons.ev_station, Colors.green),
          box('ว่าง', '$avail', Icons.check_circle, Colors.teal),
          box('กำลังชาร์จ', '$charging', Icons.bolt, Colors.blue),
          box('รวม kW', power.toStringAsFixed(0), Icons.speed, Colors.orange),
        ],
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('ทั้งหมด'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
          ),
          for (final s in ChargerStatus.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(ChargerStatus.label(s)),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(Charger c) {
    final color = ChargerStatus.color(c.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.ev_station, color: color),
        ),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${c.location}\n${c.powerKw.toStringAsFixed(0)} kW • ${c.connector}'
            '${c.note.isEmpty ? '' : '\n${c.note}'}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(ChargerStatus.label(c.status),
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
            SizedBox(
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz, size: 20),
                onSelected: (v) async {
                  if (v == 'edit') {
                    _edit(c);
                  } else if (v == 'delete') {
                    _confirmDelete(c);
                  } else if (v.startsWith('status:')) {
                    final s = v.substring(7);
                    await ChargerController.updateStatus(c.id, s);
                    _msg('เปลี่ยนสถานะเป็น "${ChargerStatus.label(s)}"');
                  }
                },
                itemBuilder: (_) => [
                  for (final s in ChargerStatus.all)
                    if (s != c.status)
                      PopupMenuItem(
                        value: 'status:$s',
                        child: Text('เปลี่ยนเป็น ${ChargerStatus.label(s)}'),
                      ),
                  if (widget.me.isAdmin) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                    const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Charger>>(
      stream: ChargerController.stream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!;
        final list =
            _filter == null ? all : all.where((c) => c.status == _filter).toList();
        return Column(
          children: [
            _summary(all),
            _filters(),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('ไม่พบข้อมูลสถานีชาร์จ'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => _tile(list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}
