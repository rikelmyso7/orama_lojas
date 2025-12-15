import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orama_lojas/routes/routes.dart';
import 'package:orama_lojas/widgets/my_menu.dart';
import 'package:share_plus/share_plus.dart';

class ChecklistPage extends StatefulWidget {
  final String storeName;
  const ChecklistPage({super.key, required this.storeName});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checklists ${widget.storeName}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
        scrolledUnderElevation: 0,
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Abertura'),
            Tab(text: 'Fechamento'),
          ],
        ),
      ),
      drawer: Menu(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChecklistStream('ABERTURA'),
          _buildChecklistStream('FECHAMENTO'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff60C03D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Adicionar',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.pushNamed(context, RouteName.add_checklist_info);
        },
      ),
    );
  }

  Widget _buildChecklistStream(String periodo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('checklist_resultados')
          .where('periodo', isEqualTo: periodo)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum checklist encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final loja = data['loja'] ?? '';
            final funcionario = data['funcionario'] ?? '';
            final dataStr = data['data'] ?? '';
            final itens = List<Map<String, dynamic>>.from(data['itens'] ?? []);

            final total = itens.length;
            final feitos = itens.where((e) => e['feito'] == true).length;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading:
                    const Icon(Icons.assignment_turned_in, color: Colors.green),
                title: Text(
                  '$loja • $periodo'.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Funcionário: $funcionario'),
                    Text('Data: $dataStr'),
                    Text('Itens feitos: $feitos / $total'),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _mostrarDetalhes(context, data);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> data) {
    final itens = List<Map<String, dynamic>>.from(data['itens'] ?? []);
    final funcionario = data['funcionario'] ?? '';
    final loja = data['loja'] ?? '';
    final periodo = data['periodo'] ?? '';
    final dataStr = data['data'] ?? '';

    // Função para compartilhar
    void _compartilhar() {
      final buffer = StringBuffer();
      buffer.writeln('Checklist $loja - $periodo');
      buffer.writeln('Funcionário: $funcionario');
      buffer.writeln('Data: $dataStr');
      buffer.writeln('Itens:');
      for (var item in itens) {
        final nome = item['nome'] ?? '';
        final feito = item['feito'] == true ? '✅' : '❌';
        buffer.writeln('- $nome: $feito');
      }
      Share.share(buffer.toString());
    }

    // Função para editar (implemente conforme sua lógica)
    void _editar() {
      // Aqui você pode navegar para uma tela de edição e passar os dados
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Função de edição ainda não implementada')),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detalhes do Checklist',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                            onPressed: _editar,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            tooltip: 'Compartilhar',
                            onPressed: _compartilhar,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: itens.length,
                    itemBuilder: (_, i) {
                      final item = itens[i];
                      return ListTile(
                        title: Text(item['nome'] ?? ''),
                        trailing: Icon(
                          item['feito'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: item['feito'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
