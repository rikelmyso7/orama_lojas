import 'dart:developer' as dev;
import 'package:app_installer/app_installer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String title;
  final String message;
  final String version;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.title,
    required this.message,
    required this.version,
  });

  @override
  String toString() =>
      'UpdateInfo(latest=$latestVersion, url=$apkUrl, title=$title)';
}

class UpdateService {
  static const _logName = 'UpdateService';
  static const _githubApiUrl =
      'https://api.github.com/repos/rikelmyso7/orama_lojas/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    dev.log('🔍 Iniciando verificação de atualização…', name: _logName);

    try {
      // 1. Versão instalada
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      dev.log('Versão instalada: $currentVersion', name: _logName);

      // 2. Consulta ao GitHub Releases
      final dio = Dio();
      final response = await dio.get(
        _githubApiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );

      final data = response.data;
      dev.log('Release recebida: ${data['tag_name']}', name: _logName);

      if (data == null || data['tag_name'] == null) {
        dev.log('❌ Release não encontrada — sem atualização.', name: _logName);
        return null;
      }

      // Remove o 'v' do início da tag (v3.0.6 -> 3.0.6)
      final tagName = data['tag_name'].toString();
      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      if (latestVersion == currentVersion) {
        dev.log('✅ App já está na última versão ($currentVersion).',
            name: _logName);
        return null;
      }

      // 3. Buscar URL do APK nos assets
      String? apkUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null && assets.isNotEmpty) {
        for (final asset in assets) {
          final name = asset['name']?.toString() ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url']?.toString();
            break;
          }
        }
      }

      if (apkUrl == null || apkUrl.isEmpty) {
        dev.log('❌ APK não encontrado nos assets da release.', name: _logName);
        return null;
      }

      // 4. Nova atualização disponível
      final info = UpdateInfo(
        latestVersion: latestVersion,
        apkUrl: apkUrl,
        title: data['name']?.toString() ?? 'Nova versão disponível',
        message: data['body']?.toString() ??
            'Há uma nova versão do app disponível.',
        version: latestVersion,
      );

      dev.log('🚀 Atualização encontrada: $info', name: _logName);
      return info;
    } catch (e, s) {
      dev.log('⚠️ Erro ao checar atualização: $e',
          name: _logName, error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> openApk(String url) async {
    final canLaunch = await canLaunchUrl(Uri.parse(url));
    print('Pode abrir? $canLaunch');

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      debugPrint('❌ Não foi possível abrir $url');
    }
  }

  Future<void> downloadAndInstall(
    String url, {
    Function(double progress, String downloaded, String total)? onDownloadProgress,
    Function(String status)? onStatusUpdate,
  }) async {
    final tempPath = '${(await getTemporaryDirectory()).path}/app-release.apk';
    dev.log('Caminho temporário: $tempPath', name: _logName);

    try {
      // 1. Baixar com progresso
      onStatusUpdate?.call('Iniciando download...');
      dev.log('🔽 Iniciando download do APK...', name: _logName);

      await Dio().download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final downloadedMB = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(1);

            onDownloadProgress?.call(progress, downloadedMB, totalMB);
            dev.log('📈 Progresso download: ${(progress * 100).toStringAsFixed(1)}% ($downloadedMB/$totalMB MB)',
                name: _logName);
          }
        },
      );

      onStatusUpdate?.call('Download concluído. Preparando instalação...');
      dev.log('✅ Download concluído', name: _logName);

      // 2. Chamar instalador nativo
      onStatusUpdate?.call('Iniciando instalação...');
      dev.log('📱 Iniciando instalação do APK...', name: _logName);

      await AppInstaller.installApk(tempPath);

      onStatusUpdate?.call('Instalação iniciada');
      dev.log('🎉 Instalação iniciada com sucesso', name: _logName);

    } catch (e, s) {
      dev.log('❌ Erro durante download/instalação: $e',
          name: _logName, error: e, stackTrace: s);
      onStatusUpdate?.call('Erro: $e');
      rethrow;
    }
  }
}
