import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_lojas/services/google_sheets_service.dart';
import 'package:orama_lojas/utils/phone_input_formatter.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:orama_lojas/widgets/my_button.dart';
import 'package:orama_lojas/widgets/my_textfield.dart';
import 'package:orama_lojas/widgets/my_textstyle.dart';

class CadastroClientePage extends StatefulWidget {
  const CadastroClientePage({super.key});

  @override
  State<CadastroClientePage> createState() => _CadastroClientePageState();
}

class _CadastroClientePageState extends State<CadastroClientePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _preferenciasController = TextEditingController();
  String? _lojaSelecionada;

  String _getLojaDoUsuario() {
    final userId = GetStorage().read('userId');
    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "Orama Paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "Orama Itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "Orama Retiro";
      case "pkphd3pmn4MQSGQNJx0DPeWr9m52":
        return "Orama Mercadao";
      case "NQ9PFI86vvaWmQqARzygTylxqzh1":
        return "Platz";
      default:
        return "";
    }
  }

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final loja = _getLojaDoUsuario();
    if (loja.isNotEmpty) {
      _lojaSelecionada = loja;
    }
  }

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lojaSelecionada == null) {
      ShowSnackBar(context, 'Por favor, selecione uma loja.', Colors.red);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final telefone = _telefoneController.text.trim();
      final preferencias = _preferenciasController.text.trim();
      final loja = _lojaSelecionada!;

      await FirebaseFirestore.instance.collection('clientes').add({
        'nome': nome,
        'telefone': telefone,
        'preferencias': preferencias,
        'loja': loja,
        'data_cadastro': FieldValue.serverTimestamp(),
      });

      await GoogleSheetsService.adicionarCliente(
        nome: nome,
        telefone: telefone,
        preferencias: preferencias,
        loja: loja,
      );

      ShowSnackBar(context, 'Cliente cadastrado com sucesso!', Colors.green);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      _nomeController.clear();
      _telefoneController.clear();
      _preferenciasController.clear();
      final lojaAtual = _getLojaDoUsuario();
      setState(() {
        _lojaSelecionada = lojaAtual.isNotEmpty ? lojaAtual : null;
      });
    } catch (e) {
      ShowSnackBar(context, 'Erro ao cadastrar cliente: $e', Colors.red);
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
        title: Text(
          'Cadastro de Cliente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff60C03D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "Preencha os dados",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              MyTextField(
                controller: _nomeController,
                hintText: 'Nome do Cliente',
                prefixicon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              MyTextField(
                controller: _telefoneController,
                hintText: 'Telefone',
                keyBordType: TextInputType.phone,
                prefixicon: const Icon(Icons.phone_outlined),
                inputFormatters: [PhoneInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              MyTextField(
                controller: _preferenciasController,
                hintText: 'Preferências',
                prefixicon: const Icon(Icons.star_border),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "Loja",
                  style: MyTextStyle.semiTitle,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  initialValue: _lojaSelecionada ?? '',
                  enabled: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.store_outlined),
                    prefixIconColor: Colors.black38,
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              MyButton(
                buttonName: 'Cadastrar Cliente',
                enabled: !_isSaving,
                onTap: _salvarCliente,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
