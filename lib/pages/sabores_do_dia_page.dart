import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/services/google_sheets_service.dart';
import 'package:orama_lojas/services/notification_service.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:orama_lojas/widgets/my_button.dart';
import 'package:orama_lojas/widgets/my_textstyle.dart';
import 'package:orama_lojas/others/sabores_dia.dart';

class SaboresDoDiaPage extends StatefulWidget {
  const SaboresDoDiaPage({super.key});

  @override
  State<SaboresDoDiaPage> createState() => _SaboresDoDiaPageState();
}

class _SaboresDoDiaPageState extends State<SaboresDoDiaPage> {
  final Map<String, Map<String, bool>> _disponibilidade = {};
  DateTime? _ultimaAtualizacao;
  bool _isLoading = true;
  bool _isSaving = false;

  static const _green = Color(0xff60C03D);

  @override
  void initState() {
    super.initState();
    _inicializarSabores();
    _carregarDisponibilidade();
  }

  void _inicializarSabores() {
    saboresDia.forEach((categoria, sabores) {
      _disponibilidade[categoria] = {};
      for (var sabor in sabores) {
        _disponibilidade[categoria]![sabor] = false;
      }
    });
  }

  Future<void> _carregarDisponibilidade() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracoes_loja')
          .doc('sabores_do_dia')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime? updatedAt;

        if (data['_updatedAt'] != null) {
          updatedAt = (data['_updatedAt'] as Timestamp).toDate();
        }

        setState(() {
          _ultimaAtualizacao = updatedAt;
          data.forEach((categoria, sabores) {
            if (categoria == '_updatedAt') return;
            if (_disponibilidade.containsKey(categoria)) {
              (sabores as Map<String, dynamic>).forEach((sabor, disponivel) {
                if (_disponibilidade[categoria]!.containsKey(sabor)) {
                  _disponibilidade[categoria]![sabor] = disponivel as bool;
                }
              });
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar disponibilidade: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarSabores() async {
    setState(() => _isSaving = true);

    try {
      final agora = DateTime.now();
      final payload = {
        ..._disponibilidade,
        '_updatedAt': Timestamp.fromDate(agora),
      };

      await FirebaseFirestore.instance
          .collection('configuracoes_loja')
          .doc('sabores_do_dia')
          .set(payload);

      await GoogleSheetsService.salvarSaboresDia(_disponibilidade);
      await NotificationService.cancelarPersistente();

      setState(() => _ultimaAtualizacao = agora);
      if (!mounted) return;
      ShowSnackBar(context, 'Sabores do dia atualizados!', Colors.green);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ShowSnackBar(context, 'Erro ao salvar: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool get _atualizadoHoje {
    if (_ultimaAtualizacao == null) return false;
    final hoje = DateTime.now();
    return _ultimaAtualizacao!.year == hoje.year &&
        _ultimaAtualizacao!.month == hoje.month &&
        _ultimaAtualizacao!.day == hoje.day;
  }

  String get _textoUltimaAtualizacao {
    if (_ultimaAtualizacao == null) return 'Nunca atualizado';
    return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR')
        .format(_ultimaAtualizacao!);
  }

  Widget _buildStatusHeader() {
    final atualizado = _atualizadoHoje;
    final corFundo =
        atualizado ? const Color(0xffE8F5E9) : const Color(0xffFFF3E0);
    final corBorda = atualizado ? _green : const Color(0xffFF8F00);
    final corIcone = atualizado ? _green : const Color(0xffFF8F00);
    final icone =
        atualizado ? Icons.check_circle_rounded : Icons.warning_rounded;
    final titulo = atualizado
        ? 'Atualizado hoje'
        : _ultimaAtualizacao == null
            ? 'Nunca atualizado'
            : 'Última vez atualizado: ${DateFormat('HH:mm:ss dd/MM', 'pt_BR').format(_ultimaAtualizacao!)}';
    final subtitulo = atualizado
        ? 'Última atualização: $_textoUltimaAtualizacao'
        : 'Atualize os sabores disponíveis para hoje.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corBorda, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: corIcone, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: corIcone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sabores do Dia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: _disponibilidade.keys.map((categoria) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              categoria,
                              style: MyTextStyle.mediunTitle.copyWith(
                                color: _green,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          ...(_disponibilidade[categoria]!.keys.map((sabor) {
                            return CheckboxListTile(
                              title: Text(
                                sabor,
                                style: MyTextStyle.defaultStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              value: _disponibilidade[categoria]![sabor],
                              activeColor: _green,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              onChanged: (bool? value) {
                                setState(() {
                                  _disponibilidade[categoria]![sabor] =
                                      value ?? false;
                                });
                              },
                            );
                          }).toList()),
                          const Divider(thickness: 1, height: 30),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                MyButton(
                  buttonName: 'Atualizar Sabores',
                  enabled: !_isSaving,
                  onTap: _salvarSabores,
                ),
              ],
            ),
    );
  }
}
