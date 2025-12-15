// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChecklistStore on _ChecklistStore, Store {
  late final _$aberturaAtom =
      Atom(name: '_ChecklistStore.abertura', context: context);

  @override
  Checklist? get abertura {
    _$aberturaAtom.reportRead();
    return super.abertura;
  }

  @override
  set abertura(Checklist? value) {
    _$aberturaAtom.reportWrite(value, super.abertura, () {
      super.abertura = value;
    });
  }

  late final _$fechamentoAtom =
      Atom(name: '_ChecklistStore.fechamento', context: context);

  @override
  Checklist? get fechamento {
    _$fechamentoAtom.reportRead();
    return super.fechamento;
  }

  @override
  set fechamento(Checklist? value) {
    _$fechamentoAtom.reportWrite(value, super.fechamento, () {
      super.fechamento = value;
    });
  }

  late final _$checkedAtom =
      Atom(name: '_ChecklistStore.checked', context: context);

  @override
  ObservableMap<String, bool> get checked {
    _$checkedAtom.reportRead();
    return super.checked;
  }

  @override
  set checked(ObservableMap<String, bool> value) {
    _$checkedAtom.reportWrite(value, super.checked, () {
      super.checked = value;
    });
  }

  late final _$loadAllAsyncAction =
      AsyncAction('_ChecklistStore.loadAll', context: context);

  @override
  Future<void> loadAll() {
    return _$loadAllAsyncAction.run(() => super.loadAll());
  }

  late final _$_ChecklistStoreActionController =
      ActionController(name: '_ChecklistStore', context: context);

  @override
  void toggle(String listId, int idx, bool value) {
    final _$actionInfo = _$_ChecklistStoreActionController.startAction(
        name: '_ChecklistStore.toggle');
    try {
      return super.toggle(listId, idx, value);
    } finally {
      _$_ChecklistStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetAll() {
    final _$actionInfo = _$_ChecklistStoreActionController.startAction(
        name: '_ChecklistStore.resetAll');
    try {
      return super.resetAll();
    } finally {
      _$_ChecklistStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
abertura: ${abertura},
fechamento: ${fechamento},
checked: ${checked}
    ''';
  }
}
