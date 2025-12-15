import 'package:mobx/mobx.dart';
import 'package:get_storage/get_storage.dart';
import '../models/checklist_model.dart';
import '../services/checklist_service.dart';

part 'checklist_store.g.dart';

class ChecklistStore = _ChecklistStore with _$ChecklistStore;

abstract class _ChecklistStore with Store {
  final _svc = ChecklistService();
  final _box = GetStorage();                     // grava check localmente

  /// Chave base: "abertura__item_0"
  String _key(String listId, int idx) => '${listId}__item_$idx';

  @observable
  Checklist? abertura;

  @observable
  Checklist? fechamento;

  @observable
  ObservableMap<String, bool> checked = ObservableMap();

  // ---------- carregamento ----------
  @action
  Future<void> loadAll() async {
    abertura  = await _svc.fetchChecklist('abertura');
    fechamento = await _svc.fetchChecklist('fechamento');

    // popula mapa checked a partir do cache local
    for (final list in [abertura, fechamento]) {
      if (list == null) continue;
      for (var i = 0; i < list.itens.length; i++) {
        final k = _key(list.id, i);
        checked[k] = _box.read(k) ?? false;
      }
    }
  }

  // ---------- marca / desmarca ----------
  @action
  void toggle(String listId, int idx, bool value) {
    final k = _key(listId, idx);
    checked[k] = value;
    _box.write(k, value);            // persiste offline
  }

  bool isChecked(String listId, int idx) =>
      checked[_key(listId, idx)] ?? false;

  // ---------- reset (ex.: todo dia) ----------
  @action
  void resetAll() {
    for (final k in checked.keys) {
      checked[k] = false;
      _box.remove(k);
    }
  }
}
