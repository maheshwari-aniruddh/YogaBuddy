import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  Future<File> generatePdf(List<JournalEntry> entries) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();
    final emojiFont = await PdfGoogleFonts.notoColorEmoji();

    // Sort entries by date
    entries.sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          icons: emojiFont,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('My Journal', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.pink400)),
                pw.Text(DateFormat('MMMM d, yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          ...entries.map((entry) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: _getMoodColor(entry.mood),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'Mood: ${entry.mood}/5',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  if (entry.good.isNotEmpty) ...[
                    pw.Text('What went well?', style: pw.TextStyle(fontSize: 10, color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
                    pw.Text(entry.good, style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 5),
                  ],
                  if (entry.bad.isNotEmpty) ...[
                    pw.Text('Challenges', style: pw.TextStyle(fontSize: 10, color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
                    pw.Text(entry.bad, style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 5),
                  ],
                  if (entry.gratitude.isNotEmpty) ...[
                    pw.Text('Gratitude', style: pw.TextStyle(fontSize: 10, color: PdfColors.pink700, fontWeight: pw.FontWeight.bold)),
                    pw.Text(entry.gratitude, style: const pw.TextStyle(fontSize: 11)),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Wrap(
                      spacing: 5,
                      children: entry.tags.map((t) => pw.Text('#$t', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue600))).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/journal_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  PdfColor _getMoodColor(int mood) {
    switch (mood) {
      case 1: return PdfColors.red300;
      case 2: return PdfColors.orange300;
      case 3: return PdfColors.blue300;
      case 4: return PdfColors.lightGreen300;
      case 5: return PdfColors.green400;
      default: return PdfColors.grey400;
    }
  }
}
