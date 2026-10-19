import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaCocina extends StatelessWidget {
  const PantallaCocina({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Comandas Pendientes - COCINA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comandas')
            .where('estado', isEqualTo: 'PENDIENTE')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Sin comandas pendientes.\n¡A descansar un rato, jefa!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.grey)),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return _construirTarjetaComandaCocina(context, doc);
            },
          );
        },
      ),
    );
  }

  Widget _construirTarjetaComandaCocina(BuildContext context, QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var items = data['items'] as List<dynamic>? ?? [];
    var timestamp = data['fecha'] as Timestamp;
    String horaFormateada = DateFormat('hh:mm a').format(timestamp.toDate());
    String nombreMesero = data['mesero_nombre'] ?? 'Sin Nombre';

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
            child: Column(
              children: [
                Text('${data['mesa']}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('👤 $nombreMesero', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('⏰ $horaFormateada', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                var item = items[i];
                int cantidad = item['cantidad'] ?? 0;
                String platillo = item['nombre'] ?? 'Sin Nombre';
                String comentario = item['comentario'] ?? '';

                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Text('$cantidad', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                      title: Text(platillo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      subtitle: comentario.isNotEmpty ? Text('📝 Nota: $comentario', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton.icon(
              onPressed: () => _marcarComandaComoLista(context, doc.id),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.check_circle),
              label: const Text('¡PLATILLOS LISTOS!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _marcarComandaComoLista(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('comandas').doc(docId).update({'estado': 'LISTO'});
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Comanda despachada!'), backgroundColor: Colors.green)
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}