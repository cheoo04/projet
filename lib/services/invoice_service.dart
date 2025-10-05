import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  static const String _companyName = 'Pharrell Phone';
  static const String _companyAddress = '''Adresse de l'entreprise
Ville, Code Postal
Pays''';
  static const String _companyPhone = '+33 1 23 45 67 89';
  static const String _companyEmail = 'contact@pharrellphone.com';

  /// Génère une facture PDF pour une commande donnée
  Future<Uint8List> generateInvoicePdf(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo et infos entreprise
              _buildHeader(),

              pw.SizedBox(height: 30),

              // Titre de la facture
              _buildTitle(order),

              pw.SizedBox(height: 20),

              // Informations client et commande
              _buildOrderInfo(order),

              pw.SizedBox(height: 30),

              // Tableau des articles
              _buildItemsTable(order),

              pw.SizedBox(height: 20),

              // Total
              _buildTotal(order),

              pw.Spacer(),

              // Pied de page
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Sauvegarde la facture et retourne le chemin du fichier
  Future<String> saveInvoice(Order order) async {
    final pdfBytes = await generateInvoicePdf(order);
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'facture_${order.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Affiche le dialog de prévisualisation et d'impression
  Future<void> showInvoicePreview(Order order) async {
    final pdfBytes = await generateInvoicePdf(order);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Facture ${order.id}',
    );
  }

  /// Partage la facture
  Future<void> shareInvoice(Order order) async {
    final pdfBytes = await generateInvoicePdf(order);

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'facture_${order.id}.pdf',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _companyName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(_companyAddress, style: const pw.TextStyle(fontSize: 12)),
            pw.Text(
              'Tél: $_companyPhone',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Email: $_companyEmail',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Center(
            child: pw.Text('📱', style: const pw.TextStyle(fontSize: 40)),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTitle(Order order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'FACTURE',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'N° ${order.id.substring(0, 8).toUpperCase()}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildOrderInfo(Order order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Informations client
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FACTURÉ À:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  order.customerName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  order.customerEmail,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  order.customerPhone,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ADRESSE DE LIVRAISON:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  order.deliveryAddress,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(width: 20),

        // Informations commande
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DÉTAILS COMMANDE:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildInfoRow('Commande:', '#${order.id.substring(0, 8)}'),
                _buildInfoRow(
                  'Date:',
                  DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                ),
                _buildInfoRow('Statut:', order.status.fullDisplay),
                _buildInfoRow('Articles:', '${order.items.length} produit(s)'),
                if (order.notes?.isNotEmpty == true)
                  _buildInfoRow('Notes:', order.notes!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Order order) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildTableHeaderCell('PRODUIT'),
            _buildTableHeaderCell('QTÉ'),
            _buildTableHeaderCell('PRIX UNIT.'),
            _buildTableHeaderCell('TOTAL'),
          ],
        ),

        // Lignes des articles
        ...order.items.map(
          (item) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: order.items.indexOf(item) % 2 == 0
                  ? PdfColors.grey50
                  : PdfColors.white,
            ),
            children: [
              _buildTableCell(item.productName),
              _buildTableCell(
                item.quantity.toString(),
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                '${item.unitPrice.toStringAsFixed(0)} FCFA',
                alignment: pw.Alignment.centerRight,
              ),
              _buildTableCell(
                '${item.totalPrice.toStringAsFixed(0)} FCFA',
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  pw.Widget _buildTotal(Order order) {
    final subtotal = order.totalAmount;
    final tva = subtotal * 0.18; // TVA 18%
    final total = subtotal + tva;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          children: [
            _buildTotalRow(
              'Sous-total:',
              '${subtotal.toStringAsFixed(0)} FCFA',
            ),
            _buildTotalRow('TVA (18%):', '${tva.toStringAsFixed(0)} FCFA'),
            pw.Divider(color: PdfColors.grey600),
            _buildTotalRow(
              'TOTAL À PAYER:',
              '${total.toStringAsFixed(0)} FCFA',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: pw.FontWeight.bold,
              color: isTotal ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONDITIONS DE PAIEMENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Paiement à réception. En cas de retard de paiement, des pénalités pourront être appliquées.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'Merci de votre confiance !',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
