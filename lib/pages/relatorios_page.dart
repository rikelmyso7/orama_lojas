import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/pages/DataView_page.dart';
import 'package:orama_lojas/pages/add_rel_info.dart';
import 'package:orama_lojas/pages/editarRelatorio_page.dart';
import 'package:orama_lojas/pages/especific_page/DataEspecificoView.dart';
import 'package:orama_lojas/pages/teste.dart';
import 'package:orama_lojas/utils/exit_dialog_utils.dart';
import 'package:orama_lojas/widgets/my_menu.dart';
import 'package:provider/provider.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:share_plus/share_plus.dart';

class RelatoriosPage extends StatefulWidget {
  @override
  _RelatoriosPageState createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  @override
  void initState() {
    super.initState();
    final store = Provider.of<StockStore>(context, listen: false);
    store.fetchReports();
    validateAndSyncUserId();
  }

  String getStoreName() {
    final userId = GetStorage().read('userId');

    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "Orama Paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "Orama Itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "Orama Retiro";
      case "NQ9PFI86vvaWmQqARzygTylxqzh1":
        return "Platz";
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

  Future<void> validateAndSyncUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await GetStorage().write('userId', currentUser.uid);
    } else {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldPop = await DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Confirmação de Saída',
              content: 'Você deseja sair do aplicativo?',
              confirmText: 'Sair',
              cancelText: 'Não',
              onConfirm: () {
                exit(0);
              },
            ) ??
            false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 4,
              leading: isMobile
                  ? Builder(
                      builder: (BuildContext context) {
                        return IconButton(
                          icon: Icon(Icons.menu),
                          color: Colors.white,
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        );
                      },
                    )
                  : null,
              title: const Text(
                "Relatórios",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: const Color(0xff60C03D),
            ),
            drawer: Menu(),
            body: Row(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => store.fetchReports(),
                    child: Observer(
                      builder: (_) {
                        if (store.isLoading) {
                          // Exibe um indicador de carregamento
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (store.reports.isEmpty) {
                          // store.fetchReports();
                          return Center(
                              child: Text("Nenhum relatório disponível"));
                        }
                        return ListView.builder(
                          itemCount: store.reports.length,
                          itemBuilder: (context, index) {
                            final sortedReports =
                                List<Map<String, dynamic>>.from(store.reports)
                                  ..sort((a, b) {
                                    final dateFormat =
                                        DateFormat('dd/MM/yyyy HH:mm');
                                    final dateA = a['Data'] != null
                                        ? dateFormat.parse(a['Data'], true)
                                        : DateTime(0);
                                    final dateB = b['Data'] != null
                                        ? dateFormat.parse(b['Data'], true)
                                        : DateTime(0);
                                    return dateB
                                        .compareTo(dateA); // Ordem decrescente
                                  });

                            final report = sortedReports[index];
                            final data = report['Data'] ?? '';
                            final loja = report['Loja'] ?? '';
                            final cidade = report['Cidade'] ?? '';
                            final name = report['Nome do usuario'] ?? '';
                            final tipo_relatorio =
                                report['Tipo Relatorio'] ?? '';

                            final dateString = report['Data'] ?? '';
                            DateTime? parsedDate;

                            try {
                              parsedDate = DateFormat('dd/MM/yyyy HH:mm')
                                  .parse(dateString);
                            } catch (e) {
                              print("Erro ao converter a data: $e");
                            }

                            final dayOfWeek = parsedDate != null
                                ? DateFormat('EEEE', 'pt_BR').format(parsedDate)
                                : '';

                            return Card(
                              margin: EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "$loja",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditarRelatorioPage(
                                                      nome: name,
                                                      data: data,
                                                      city: cidade,
                                                      loja: loja,
                                                      reportData: report,
                                                      reportId: report['ID'],
                                                      tipo_relatorio:
                                                          'Relatório Geral',
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.edit),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                final message = store
                                                    .formatRelatorioForWhatsApp(
                                                        report);
                                                await Share.share(message);
                                              },
                                              icon: FaIcon(
                                                  FontAwesomeIcons.whatsapp),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DataViewPage(
                                                            report: report),
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.remove_red_eye),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text("Responsável: $name",
                                        style: TextStyle(fontSize: 16)),
                                    Text(
                                      "Tipo: $tipo_relatorio",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                    Text(
                                      "Data: $data",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                    Text(
                                      "Dia da Semana: $dayOfWeek",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: const Color(0xff60C03D),
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: Text(
                'Adicionar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddRelatorioInfo(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
