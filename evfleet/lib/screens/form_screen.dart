import 'package:flutter/material.dart';
import '../controllers/charger_controller.dart';
import '../models/charger.dart';

/// ใช้ทั้งเพิ่ม (charger == null) และแก้ไข (charger != null)
class FormScreen extends StatefulWidget {
  final Charger? charger;
  final VoidCallback? onSaved;
  const FormScreen({super.key, this.charger, this.onSaved});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _power = TextEditingController();
  final _note = TextEditingController();
  String _connector = Charger.connectors.first;
  String _status = ChargerStatus.available;
  bool _saving = false;

  bool get _editing => widget.charger != null;

  @override
  void initState() {
    super.initState();
    final c = widget.charger;
    if (c != null) {
      _name.text = c.name;
      _location.text = c.location;
      _power.text = c.powerKw.toStringAsFixed(0);
      _note.text = c.note;
      _connector = c.connector;
      _status = c.status;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _power.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final power = double.parse(_power.text.trim());
      if (_editing) {
        await ChargerController.update(
          widget.charger!.id,
          name: _name.text.trim(),
          location: _location.text.trim(),
          powerKw: power,
          connector: _connector,
          status: _status,
          note: _note.text.trim(),
        );
      } else {
        await ChargerController.add(
          name: _name.text.trim(),
          location: _location.text.trim(),
          powerKw: power,
          connector: _connector,
          status: _status,
          note: _note.text.trim(),
        );
        _formKey.currentState!.reset();
        _name.clear();
        _location.clear();
        _power.clear();
        _note.clear();
        _connector = Charger.connectors.first;
        _status = ChargerStatus.available;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(_editing ? 'แก้ไขสถานีเรียบร้อย' : 'เพิ่มสถานีเรียบร้อย')));
      widget.onSaved?.call();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'ชื่อสถานี / หัวชาร์จ',
              prefixIcon: Icon(Icons.ev_station),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อสถานี' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'ที่ตั้ง',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณากรอกที่ตั้ง' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _power,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'กำลังไฟ (kW)',
              prefixIcon: Icon(Icons.bolt),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse(v?.trim() ?? '');
              if (n == null) return 'กรุณากรอกตัวเลข';
              if (n < 1 || n > 350) return 'กำลังไฟต้องอยู่ระหว่าง 1-350 kW';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _connector,
            decoration: const InputDecoration(
              labelText: 'ประเภทหัวชาร์จ',
              prefixIcon: Icon(Icons.power),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in Charger.connectors)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _connector = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'สถานะ',
              prefixIcon: Icon(Icons.info_outline),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in ChargerStatus.all)
                DropdownMenuItem(value: s, child: Text(ChargerStatus.label(s))),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ (ไม่บังคับ)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_editing ? 'บันทึกการแก้ไข' : 'บันทึก'),
            ),
          ),
        ],
      ),
    );

    if (_editing) {
      return Scaffold(appBar: AppBar(title: const Text('แก้ไขสถานีชาร์จ')), body: form);
    }
    return form;
  }
}
