import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:orama_lojas/routes/routes.dart';
import 'package:orama_lojas/services/notification_service.dart';
import 'package:orama_lojas/stores/checklist_store.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:provider/provider.dart';
import 'auth/firebase_options.dart';

Future<void> main() async {
  await initializeDateFormatting('pt_BR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  await NotificationService.agendarLembreteDiario(hora: 8, minuto: 0);
  await _sincronizarNotificacaoPersistente();

  runApp(
    MultiProvider(
      providers: [
        Provider<StockStore>(create: (_) => StockStore()),
        Provider<ChecklistStore>(create: (_) => ChecklistStore()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Verifica se os sabores do dia já foram atualizados hoje.
/// Se não, exibe notificação persistente na barra de status.
Future<void> _sincronizarNotificacaoPersistente() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('configuracoes_loja')
        .doc('sabores_do_dia')
        .get();

    bool atualizadoHoje = false;

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['_updatedAt'] != null) {
        final ultima = (data['_updatedAt'] as Timestamp).toDate();
        final hoje = DateTime.now();
        atualizadoHoje = ultima.year == hoje.year &&
            ultima.month == hoje.month &&
            ultima.day == hoje.day;
      }
    }

    if (atualizadoHoje) {
      await NotificationService.cancelarPersistente();
    } else {
      await NotificationService.mostrarPersistente();
    }
  } catch (_) {
    // Sem conexão — não altera estado da notificação
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Estoque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A676), brightness: Brightness.light)),
      routes: Routes.routes,
      initialRoute: RouteName.splash,
    );
  }
}
