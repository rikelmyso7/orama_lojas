// estoque_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstoquePage extends StatelessWidget {
  const EstoquePage({super.key});

  @override
  Widget build(BuildContext context) {
    final estoqueRef = FirebaseFirestore.instance.collection('estoque');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque Atual'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: estoqueRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Estoque vazio'));
          }

          final itens = snapshot.data!.docs;

          return ListView.builder(
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final item = itens[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(item['nome'] ?? 'Sem nome'),
                subtitle: Text('Categoria: ${item['categoria'] ?? 'N/A'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Qtd: ${item['quantidade'] ?? 0}'),
                    Text('Peso: ${item['peso'] ?? 0}g'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
