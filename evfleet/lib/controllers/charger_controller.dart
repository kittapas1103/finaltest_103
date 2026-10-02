import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/charger.dart';

class ChargerController {
  ChargerController._();

  static final _col = FirebaseFirestore.instance.collection('chargers');

  static Stream<List<Charger>> stream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Charger.fromDoc(d)).toList());
  }

  static Future<void> add({
    required String name,
    required String location,
    required double powerKw,
    required String connector,
    required String status,
    required String note,
  }) {
    return _col.add({
      'name': name,
      'location': location,
      'powerKw': powerKw,
      'connector': connector,
      'status': status,
      'note': note,
      'createdBy': FirebaseAuth.instance.currentUser?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> update(
    String id, {
    required String name,
    required String location,
    required double powerKw,
    required String connector,
    required String status,
    required String note,
  }) {
    return _col.doc(id).update({
      'name': name,
      'location': location,
      'powerKw': powerKw,
      'connector': connector,
      'status': status,
      'note': note,
    });
  }

  static Future<void> updateStatus(String id, String status) =>
      _col.doc(id).update({'status': status});

  static Future<void> delete(String id) => _col.doc(id).delete();
}
