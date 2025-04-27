import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:orama_lojas/routes/routes.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:provider/provider.dart';
import 'auth/firebase_options.dart';

Future<void> checkAndUpdateProvider() async {
  final googleApiAvailability = GoogleApiAvailability.instance;

  // Verifica se o Google Play Services está disponível
  GooglePlayServicesAvailability availability = await googleApiAvailability.checkGooglePlayServicesAvailability();
  if (availability == GooglePlayServicesAvailability.success) {
    print('Google Play Services está disponível.');
    try {
      await googleApiAvailability.makeGooglePlayServicesAvailable();
      print('Provider atualizado com sucesso!');
    } catch (e) {
      print('Erro ao atualizar o Provider: $e');
    }
  } else {
    print('Google Play Services não está disponível: $availability');
  }
}

Future<void> main() async {
  await initializeDateFormatting('pt_BR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await checkAndUpdateProvider();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<StockStore>(create: (_) => StockStore()),
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
        primarySwatch: Colors.blue,
      ),
      routes: Routes.routes,
      initialRoute: RouteName.splash,
    );
  }
}
