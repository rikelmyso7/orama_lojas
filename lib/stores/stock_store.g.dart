// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StockStore on _StockStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_StockStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$quantityValuesAtom =
      Atom(name: '_StockStore.quantityValues', context: context);

  @override
  ObservableMap<String, String> get quantityValues {
    _$quantityValuesAtom.reportRead();
    return super.quantityValues;
  }

  @override
  set quantityValues(ObservableMap<String, String> value) {
    _$quantityValuesAtom.reportWrite(value, super.quantityValues, () {
      super.quantityValues = value;
    });
  }

  late final _$minValuesAtom =
      Atom(name: '_StockStore.minValues', context: context);

  @override
  ObservableMap<String, String> get minValues {
    _$minValuesAtom.reportRead();
    return super.minValues;
  }

  @override
  set minValues(ObservableMap<String, String> value) {
    _$minValuesAtom.reportWrite(value, super.minValues, () {
      super.minValues = value;
    });
  }

  late final _$quantityControllersAtom =
      Atom(name: '_StockStore.quantityControllers', context: context);

  @override
  Map<String, TextEditingController> get quantityControllers {
    _$quantityControllersAtom.reportRead();
    return super.quantityControllers;
  }

  @override
  set quantityControllers(Map<String, TextEditingController> value) {
    _$quantityControllersAtom.reportWrite(value, super.quantityControllers, () {
      super.quantityControllers = value;
    });
  }

  late final _$minControllersAtom =
      Atom(name: '_StockStore.minControllers', context: context);

  @override
  Map<String, TextEditingController> get minControllers {
    _$minControllersAtom.reportRead();
    return super.minControllers;
  }

  @override
  set minControllers(Map<String, TextEditingController> value) {
    _$minControllersAtom.reportWrite(value, super.minControllers, () {
      super.minControllers = value;
    });
  }

  late final _$fetchReportsAsyncAction =
      AsyncAction('_StockStore.fetchReports', context: context);

  @override
  Future<void> fetchReports() {
    return _$fetchReportsAsyncAction.run(() => super.fetchReports());
  }

  late final _$fetchReportsEspecificoAsyncAction =
      AsyncAction('_StockStore.fetchReportsEspecifico', context: context);

  @override
  Future<void> fetchReportsEspecifico() {
    return _$fetchReportsEspecificoAsyncAction
        .run(() => super.fetchReportsEspecifico());
  }

  late final _$_StockStoreActionController =
      ActionController(name: '_StockStore', context: context);

  @override
  void initItemValues(String category, String itemName, String minimoPadrao,
      {String? tipo}) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.initItemValues');
    try {
      return super.initItemValues(category, itemName, minimoPadrao, tipo: tipo);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateMinValue(String key, String minValue) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateMinValue');
    try {
      return super.updateMinValue(key, minValue);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateQuantity(String key, String quantity) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateQuantity');
    try {
      return super.updateQuantity(key, quantity);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearFields() {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.clearFields');
    try {
      return super.clearFields();
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeItemFromReport(
      {required String reportId,
      required String category,
      required String name}) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.removeItemFromReport');
    try {
      return super.removeItemFromReport(
          reportId: reportId, category: category, name: name);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
quantityValues: ${quantityValues},
minValues: ${minValues},
quantityControllers: ${quantityControllers},
minControllers: ${minControllers}
    ''';
  }
}
