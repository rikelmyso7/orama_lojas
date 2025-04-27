import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_lojas/main.dart';
import 'package:orama_lojas/others/field_validators.dart';
import 'package:orama_lojas/pages/especific_page/especifico_relatorio_page.dart';
import 'package:orama_lojas/pages/formulario_page.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:orama_lojas/widgets/my_button.dart';
import 'package:orama_lojas/widgets/my_textfield.dart';
import 'package:provider/provider.dart';

class AddEspecificoInfo extends StatefulWidget {
  @override
  _AddEspecificoInfoState createState() => _AddEspecificoInfoState();
}

class _AddEspecificoInfoState extends State<AddEspecificoInfo> {
  final TextEditingController _nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier<bool>(false);

  String getStoreName() {
    final userId = GetStorage().read('userId');

    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "Orama Paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "Orama Itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "Orama Retiro";
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
      default:
        return "";
    }
  }

  String? periodoSelecionado;

  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _nameController.dispose();
    isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    isFormValid.value = _nameController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final city = cidade();
    final storeName = getStoreName();
    final store = Provider.of<StockStore>(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Novo Relatório Específico",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height / 2,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  MyTextField(
                    controller: _nameController,
                    hintText: 'Seu Nome',
                    validator: FieldValidators.validateName,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isFormValid,
                    builder: (context, isValid, child) {
                      return MyButton(
                        buttonName: 'Próximo',
                        onTap: isValid
                            ? () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EspecificoRelatorioPage(
                                        nome: _nameController.text,
                                        data: _date.toIso8601String(),
                                        loja: storeName,
                                        reportData: null,
                                        city: city, tipo_relatorio: 'Relatório Específico',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        enabled: isValid,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
