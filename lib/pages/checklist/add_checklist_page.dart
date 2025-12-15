import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_lojas/main.dart';
import 'package:orama_lojas/others/field_validators.dart';
import 'package:orama_lojas/pages/checklist/checklist_select_page.dart';
import 'package:orama_lojas/pages/formulario_page.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:orama_lojas/widgets/my_button.dart';
import 'package:orama_lojas/widgets/my_dropdown.dart';
import 'package:orama_lojas/widgets/my_textfield.dart';
import 'package:provider/provider.dart';

class AddChecklistPage extends StatefulWidget {
  @override
  _AddChecklistPageState createState() => _AddChecklistPageState();
}

class _AddChecklistPageState extends State<AddChecklistPage> {
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier<bool>(false);

  String? _funcionarioSelecionado;
  String? _periodoSelecionado;
  DateTime _date = DateTime.now();
  List<String> _funcionarios = [];

  @override
  void initState() {
    super.initState();
    _loadFuncionarios();
  }

  /// Obter nome da loja de acordo com o userId
  String getStoreName() {
    final userId = GetStorage().read('userId');
    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "retiro";
      case "NQ9PFI86vvaWmQqARzygTylxqzh1":
        return "platz";
      default:
        return "Loja";
    }
  }

  String cidade() {
    final userId = GetStorage().read('userId');
    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "Jundiaí";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "Itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "Jundiaí";
      case "NQ9PFI86vvaWmQqARzygTylxqzh1":
        return "Campinas";
      default:
        return "";
    }
  }

  Future<void> _loadFuncionarios() async {
    final storeName = getStoreName();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('funcionarios')
          .doc(storeName)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final list = data['name']; // pega o array de funcionários

        if (list is List) {
          setState(() {
            _funcionarios = List<String>.from(list);
          });
        } else {
          debugPrint('Campo "name" não é uma lista');
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar funcionários: $e');
    }
  }

  void _validateForm() {
    isFormValid.value =
        _funcionarioSelecionado != null && _periodoSelecionado != null;
  }

  @override
  Widget build(BuildContext context) {
    final storeName = getStoreName();
    final city = cidade();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Novo Checklist",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SafeArea(
          child: Container(
            // padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height / 2,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // dropdown de funcionário
                  MyDropDownButton(
                    hint: "Selecione o Funcionário",
                    options: _funcionarios,
                    value: _funcionarioSelecionado,
                    onChanged: (val) {
                      setState(() {
                        _funcionarioSelecionado = val;
                      });
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 16),

                  // dropdown de período
                  MyDropDownButton(
                    hint: "Selecione o Período",
                    options: const ['ABERTURA', 'FECHAMENTO'],
                    value: _periodoSelecionado,
                    onChanged: (val) {
                      setState(() {
                        _periodoSelecionado = val;
                      });
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: isFormValid,
                    builder: (context, isValid, _) {
                      return MyButton(
                        buttonName: 'Próximo',
                        onTap: isValid
                            ? () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChecklistSelectPage(storeName: storeName, periodo: _periodoSelecionado, funcionario: _funcionarioSelecionado!,)
                                    ),
                                  );
                                }
                              }
                            : null,
                        enabled: isValid,
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
