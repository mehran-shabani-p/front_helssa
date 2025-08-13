import 'dart:typed_data';
import 'package:pdf_text/pdf_text.dart';

class PdfService {
  Future<String> extract(Uint8List pdfBytes) async {
    final doc = await PDFDocument.fromData(pdfBytes);
    final pages = doc.pagesCount;
    final buf = StringBuffer();
    for (int i = 1; i <= pages; i++) {
      buf.writeln(await doc.pageAt(i).text);
    }
    return buf.toString().trim();
  }
}
