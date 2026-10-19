import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PantallaCajero extends StatelessWidget {
  const PantallaCajero({super.key});

  Future<void> _imprimirTicket(String folio, String mesa, double total, List items) async {
    final pdf = pw.Document();
    DateTime ahora = DateTime.now();
    String fecha = "${ahora.day.toString().padLeft(2,'0')}/${ahora.month.toString().padLeft(2,'0')}/${ahora.year}";
    String hora = "${ahora.hour > 12 ? ahora.hour - 12 : ahora.hour}:${ahora.minute.toString().padLeft(2, '0')} ${ahora.hour >= 12 ? 'p. m.' : 'a. m.'}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('   *** MR. PULPO POS *** ', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(' Punto de Venta Profesional', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.Text('       Xalapa, Veracruz     ', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.Text('--------------------------------', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Folio: ${folio.substring(0, 6).toUpperCase()}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Mesa: $mesa', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
              pw.Text('Mesero: Admin', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Fecha: $fecha $hora', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            ]),
            pw.Text('--------------------------------', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.Row(children: [
              pw.Expanded(flex: 1, child: pw.Text('Cant', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10))),
              pw.Expanded(flex: 3, child: pw.Text('Platillo', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('Importe', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10))),
            ]),
            pw.Text('--------------------------------', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            ...items.map((item) {
              double cant = (item['cantidad'] ?? 1).toDouble();
              double precio = (item['precio'] ?? (item['subtotal'] ?? 0) / cant).toDouble();
              double subtotal = cant * precio;
              return pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 1, child: pw.Text('${cant.toInt()}x', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10))),
                  pw.Expanded(flex: 3, child: pw.Text('${item['nombre']}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10))),
                  pw.Expanded(flex: 2, child: pw.Text('\$${subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10))),
                ],
              );
            }),
            pw.Text('--------------------------------', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('TOTAL:', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('\$${total.toStringAsFixed(2)}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 15),
            pw.Text('    ¡Gracias por su visita!   ', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.Text('    *** Fin de Ticket *** ', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );

    // 🔥 REVERTIDO: Se regresa a tu línea original para Windows
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _cobrar(BuildContext context, String idComanda, String mesa, double total, List items) async {
    try {
      await _imprimirTicket(idComanda, mesa, total, items);
      
      await FirebaseFirestore.instance.collection('comandas').doc(idComanda).update({
        'estado': 'PAGADO',
        'fecha': FieldValue.serverTimestamp(),
        'total': total,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cobrado e Impreso'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint("Error al procesar cobro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('comandas').where('estado', isEqualTo: 'LISTO').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No hay mesas pendientes 🏖️'));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.point_of_sale, color: Colors.green, size: 30),
                  title: Text('MESA ${data['mesa']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${(data['total'] ?? 0).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: () => _cobrar(context, docs[index].id, data['mesa'].toString(), (data['total'] ?? 0).toDouble(), data['items'] ?? []),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        child: const Text('COBRAR'),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}