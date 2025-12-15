import 'package:flutter/material.dart';
import 'package:orama_lojas/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required String apkUrl,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text('Uma nova versão do aplicativo está disponível'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mais tarde'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showProgressDialog(context, apkUrl);
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  static void _showProgressDialog(BuildContext context, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateProgressDialog(apkUrl: apkUrl),
    );
  }
}

class UpdateProgressDialog extends StatefulWidget {
  final String apkUrl;

  const UpdateProgressDialog({Key? key, required this.apkUrl})
      : super(key: key);

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  double _progress = 0.0;
  String _status = 'Preparando atualização...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await UpdateService().downloadAndInstall(
        widget.apkUrl,
        onDownloadProgress: (progress, downloaded, total) {
          setState(() {
            _progress = progress;
          });
        },
        onStatusUpdate: (status) {
          setState(() {
            _status = status;
          });
        },
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _status = 'Erro durante a atualização';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _hasError,
      child: AlertDialog(
        title: Text(
          _hasError ? 'Erro na Atualização' : 'Atualizando App',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Não feche o aplicativo durante a atualização',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (!_hasError) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text('${(_progress * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
            ],
            if (_hasError)
              Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
            if (_hasError && _errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: _hasError
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _progress = 0.0;
                      _status = 'Preparando atualização...';
                      _errorMessage = '';
                    });
                    _startDownload();
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ]
            : [],
      ),
    );
  }
}
