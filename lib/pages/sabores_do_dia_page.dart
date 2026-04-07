import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orama_lojas/services/google_sheets_service.dart';
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
  // Map para controlar a disponibilidade: {categoria: {sabor: disponivel}}
  final Map<String, Map<String, bool>> _disponibilidade = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _inicializarSabores();
    _carregarDisponibilidade();
  }

  void _inicializarSabores() {
    // Utilizando as categorias e sabores do arquivo sabores_dia.dart
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
        setState(() {
          data.forEach((categoria, sabores) {
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
      print('Erro ao carregar disponibilidade: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarSabores() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('configuracoes_loja')
          .doc('sabores_do_dia')
          .set(_disponibilidade);

      await GoogleSheetsService.salvarSaboresDia(_disponibilidade);

      ShowSnackBar(context, 'Sabores do dia atualizados!', Colors.green);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ShowSnackBar(context, 'Erro ao salvar: $e', Colors.red);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
        backgroundColor: const Color(0xff60C03D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _disponibilidade.keys.map((categoria) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              categoria,
                              style: MyTextStyle.mediunTitle.copyWith(
                                color: const Color(0xff60C03D),
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
                              activeColor: const Color(0xff60C03D),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              onChanged: (bool? value) {
                                setState(() {
                                  _disponibilidade[categoria]![sabor] = value ?? false;
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
