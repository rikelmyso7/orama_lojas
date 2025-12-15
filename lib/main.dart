import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:orama_lojas/routes/routes.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Estoque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
         colorScheme: const ColorScheme.light(
                primary: Color(0xFF00A676), brightness: Brightness.light)
      ),
      routes: Routes.routes,
      initialRoute: RouteName.splash,
    );
  }
}
