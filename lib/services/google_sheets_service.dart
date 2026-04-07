import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';

class GoogleSheetsService {
  static const _spreadsheetId =
      '1wDQoXPnMbNdP_QNI12HjaRPlB1O4r9KbGQPYuXMfeYc';
  static const _sheetClientes = 'clientes';
  static final _scopes = [SheetsApi.spreadsheetsScope];

  /// Retorna o nome da sheet de sabores para o usuário logado.
  static String _sheetSaboresDaLoja() {
    final userId = GetStorage().read('userId');
    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "sabores_paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "sabores_itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "sabores_retiro";
      case "pkphd3pmn4MQSGQNJx0DPeWr9m52":
        return "sabores_mercadao";
      case "NQ9PFI86vvaWmQqARzygTylxqzh1":
        return "sabores_platz";
      default:
        return "sabores_dia";
    }
  }

  static Future<SheetsApi> _getSheetsApi() async {
    final jsonStr =
        await rootBundle.loadString('assets/secrets/service_account.json');
    final credentials =
        ServiceAccountCredentials.fromJson(jsonDecode(jsonStr));
    final client = await clientViaServiceAccount(credentials, _scopes);
    return SheetsApi(client);
  }

  /// Sobrescreve a sheet de sabores da loja logada com a data atual e todos os sabores.
  static Future<void> salvarSaboresDia(
      Map<String, Map<String, bool>> disponibilidade) async {
    final api = await _getSheetsApi();
    final sheet = _sheetSaboresDaLoja();
    final data = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final List<List<Object>> rows = [
      [data],
      ['sabor', 'disponivel'],
    ];

    disponibilidade.forEach((_, saboresMap) {
      saboresMap.forEach((sabor, disponivel) {
        rows.add([sabor, disponivel ? 'sim' : 'não']);
      });
    });

    await api.spreadsheets.values.clear(
      ClearValuesRequest(),
      _spreadsheetId,
      sheet,
    );

    await api.spreadsheets.values.update(
      ValueRange(
        range: '$sheet!A1',
        values: rows,
      ),
      _spreadsheetId,
      '$sheet!A1',
      valueInputOption: 'RAW',
    );
  }

  /// Adiciona uma nova linha na sheet clientes.
  /// Cria o cabeçalho automaticamente se a sheet estiver vazia.
  static Future<void> adicionarCliente({
    required String nome,
    required String telefone,
    required String preferencias,
    required String loja,
  }) async {
    final api = await _getSheetsApi();

    final existing = await api.spreadsheets.values.get(
      _spreadsheetId,
      '$_sheetClientes!A1',
    );

    if (existing.values == null || existing.values!.isEmpty) {
      await api.spreadsheets.values.update(
        ValueRange(
          range: '$_sheetClientes!A1',
          values: [
            ['nome', 'telefone', 'preferencias', 'loja', 'data_cadastro'],
          ],
        ),
        _spreadsheetId,
        '$_sheetClientes!A1',
        valueInputOption: 'RAW',
      );
    }

    final data = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    await api.spreadsheets.values.append(
      ValueRange(
        values: [
          [nome, telefone, preferencias, loja, data],
        ],
      ),
      _spreadsheetId,
      '$_sheetClientes!A1',
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
    );
  }
}
