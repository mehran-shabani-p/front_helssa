import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<String> extract(Uint8List pdfBytes) async {
    final doc = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(doc);
    final buf = StringBuffer();

    for (var i = 0; i < doc.pages.count; i++) {
      buf.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
    }

    doc.dispose();
    return buf.toString().trim();
  }
}
