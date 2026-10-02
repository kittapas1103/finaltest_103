import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChargerStatus {
  static const available = 'available';
  static const charging = 'charging';
  static const offline = 'offline';
  static const maintenance = 'maintenance';
  static const all = [available, charging, offline, maintenance];

  static String label(String s) {
    switch (s) {
      case available:
        return 'ว่าง';
      case charging:
        return 'กำลังชาร์จ';
      case offline:
        return 'ออฟไลน์';
      case maintenance:
        return 'ซ่อมบำรุง';
      default:
        return s;
    }
  }

  static Color color(String s) {
    switch (s) {
      case available:
        return Colors.green;
      case charging:
        return Colors.blue;
      case offline:
        return Colors.grey;
      case maintenance:
        return Colors.orange;
      default:
        return Colors.black54;
    }
  }
}

class Charger {
  static const connectors = ['Type 2', 'CCS2', 'CHAdeMO'];

  final String id;
  final String name;
  final String location;
  final double powerKw;
  final String connector;
  final String status;
  final String note;
  final String createdBy;

  const Charger({
    required this.id,
    required this.name,
    required this.location,
    required this.powerKw,
    required this.connector,
    required this.status,
    required this.note,
    required this.createdBy,
  });

  factory Charger.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Charger(
      id: d.id,
      name: (m['name'] ?? '') as String,
      location: (m['location'] ?? '') as String,
      powerKw: (m['powerKw'] as num?)?.toDouble() ?? 0,
      connector: (m['connector'] ?? connectors.first) as String,
      status: (m['status'] ?? ChargerStatus.available) as String,
      note: (m['note'] ?? '') as String,
      createdBy: (m['createdBy'] ?? '') as String,
    );
  }
}
