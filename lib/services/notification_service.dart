import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'sabores_dia_channel';
  static const _idLembreteDiario = 1;
  static const _idPersistente = 2;

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/orama_user_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Notificação persistente (ongoing) na barra de status.
  /// Aparece enquanto os sabores do dia não forem atualizados.
  static Future<void> mostrarPersistente() async {
    await _plugin.show(
      _idPersistente,
      'Sabores do Dia pendentes',
      'Os sabores de hoje ainda não foram atualizados. Toque para abrir.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Sabores do Dia',
          channelDescription: 'Lembrete para atualizar os sabores do dia',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,        // não pode ser dispensada pelo usuário
          autoCancel: false,    // não some ao tocar
          icon: '@mipmap/orama_user_launcher',
          color: Color(0xffFF8F00),
        ),
      ),
    );
  }

  /// Remove a notificação persistente após atualizar os sabores.
  static Future<void> cancelarPersistente() async {
    await _plugin.cancel(_idPersistente);
  }

  /// Agenda lembrete diário às [hora]:[minuto] para lembrar de atualizar.
  static Future<void> agendarLembreteDiario({
    int hora = 8,
    int minuto = 0,
  }) async {
    await _plugin.cancel(_idLembreteDiario);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hora, minuto);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idLembreteDiario,
      'Sabores do Dia',
      'Não esqueça de atualizar os sabores disponíveis hoje!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Sabores do Dia',
          channelDescription: 'Lembrete diário para atualizar os sabores',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/orama_user_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
