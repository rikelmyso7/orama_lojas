import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/pages/add_rel_info.dart';
import 'package:orama_lojas/pages/editarRelatorio_page.dart';
import 'package:orama_lojas/pages/especific_page/DataEspecificoView.dart';
import 'package:orama_lojas/pages/especific_page/add_especifco_info.dart';
import 'package:orama_lojas/pages/especific_page/especifico_editar_page.dart';
import 'package:orama_lojas/utils/exit_dialog_utils.dart';
import 'package:orama_lojas/widgets/my_menu.dart';
import 'package:provider/provider.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:share_plus/share_plus.dart';

class EspecificoViewPage extends StatefulWidget {
  @override
  _EspecificoViewPageState createState() => _EspecificoViewPageState();
}

class _EspecificoViewPageState extends State<EspecificoViewPage> {
  @override
  void initState() {
    super.initState();
    final store = Provider.of<StockStore>(context, listen: false);
    store.fetchReportsEspecifico();
    validateAndSyncUserId();
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
        ) ?? false;

      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 4,
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: Icon(Icons.menu),
                    color: Colors.white,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
              title: const Text(
                "Relatórios Específicos",
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
                    onRefresh: () => store.fetchReportsEspecifico(),
                    child: Observer(
                      builder: (_) {
                        if (store.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (store.specificReports.isEmpty) {
                          return Center(
                            child:
                                Text("Nenhum relatório específico disponível"),
                          );
                        }

                        // Ordena os relatórios pela data, do mais recente ao mais antigo
                        final dateFormat = DateFormat("dd/MM/yyyy HH:mm");

                        final sortedSpecificReports =
                            List.from(store.specificReports)
                              ..sort((a, b) {
                                final dateA = dateFormat
                                    .parse(a['Data'] ?? '01/01/1970 00:00');
                                final dateB = dateFormat
                                    .parse(b['Data'] ?? '01/01/1970 00:00');
                                return dateB
                                    .compareTo(dateA); // Mais recente primeiro
                              });

                        return ListView.builder(
                          itemCount: sortedSpecificReports.length,
                          itemBuilder: (context, index) {
                            final specificReport = sortedSpecificReports[index];
                            final data = specificReport['Data'] ?? '';
                            final loja = specificReport['Loja'] ?? '';
                            final cidade = specificReport['Cidade'] ?? '';
                            final tipo_relatorio =
                                specificReport['Tipo Relatorio'] ?? '';
                            final name =
                                specificReport['Nome do usuario'] ?? '';

                            final dateString = specificReport['Data'] ?? '';
                            DateTime? parsedDate;

                            try {
                              parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditarEspecificoRelatorioPage(
                                                      nome: name,
                                                      data: data,
                                                      city: cidade,
                                                      loja: loja,
                                                      reportData:
                                                          specificReport,
                                                      reportId:
                                                          specificReport['ID'],
                                                      tipo_relatorio:
                                                          'Relatório Específico',
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.edit),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                final message = store
                                                    .formatReportForWhatsApp(
                                                        specificReport);
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
                                                        Dataespecificoview(
                                                            report:
                                                                specificReport),
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
                    builder: (context) => AddEspecificoInfo(),
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
