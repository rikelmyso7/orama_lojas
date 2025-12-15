import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_model.dart';

class ChecklistService {
  final _col = FirebaseFirestore.instance.collection('checklist');

  Future<Checklist> fetchChecklist(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) throw 'Checklist $id não encontrado';
    return Checklist.fromJson(id, doc.data()!);
  }
}
