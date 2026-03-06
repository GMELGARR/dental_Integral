import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../features/billing/domain/entities/payment.dart';
import '../../features/reports/domain/entities/report_data.dart';

/// Centralised PDF generation & sharing service for Dental Integral.
class PdfService {
  PdfService._();
  static final instance = PdfService._();

  static final _currFmt = NumberFormat('#,##0.00', 'en');
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy  HH:mm');

  // ── Theme colours (PdfColors) ──────────────────────────────────
  static const _primary = PdfColor.fromInt(0xFF0D7377);
  static const _accent = PdfColor.fromInt(0xFF00897B);
  static const _darkText = PdfColor.fromInt(0xFF1A1A1A);
  static const _mutedText = PdfColor.fromInt(0xFF6B7280);
  static const _divider = PdfColor.fromInt(0xFFE5E7EB);
  static const _bgLight = PdfColor.fromInt(0xFFF9FAFB);

  // ══════════════════════════════════════════════════════════════
  //  RECEIPT PDF
  // ══════════════════════════════════════════════════════════════

  /// Generates a professional payment receipt and shares it.
  Future<void> generateAndShareReceipt(Payment payment) async {
    final pdf = pw.Document(
      title: 'Recibo de pago – ${payment.pacienteNombre}',
      author: 'Dental Integral',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => _buildReceipt(payment),
      ),
    );

    await _shareDocument(
      pdf,
      'recibo_${payment.id.substring(0, 8)}.pdf',
    );
  }

  pw.Widget _buildReceipt(Payment payment) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────
        _clinicHeader(),
        pw.SizedBox(height: 8),
        pw.Divider(color: _primary, thickness: 2),
        pw.SizedBox(height: 12),

        // ── Title ────────────────────────────
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'RECIBO DE PAGO',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        // ── Receipt info ─────────────────────
        _infoRow('No. Recibo:', payment.id.substring(0, 8).toUpperCase()),
        _infoRow('Fecha:', _dateTimeFmt.format(payment.fecha)),
        pw.SizedBox(height: 12),
        pw.Divider(color: _divider),
        pw.SizedBox(height: 12),

        // ── Patient ──────────────────────────
        _sectionTitle('Datos del paciente'),
        pw.SizedBox(height: 6),
        _infoRow('Nombre:', payment.pacienteNombre),
        pw.SizedBox(height: 16),

        // ── Payment detail ───────────────────
        _sectionTitle('Detalle del pago'),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _bgLight,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _divider),
          ),
          child: pw.Column(
            children: [
              _detailRow('Monto:', 'Q ${_currFmt.format(payment.monto)}',
                  bold: true, big: true),
              pw.SizedBox(height: 8),
              _detailRow(
                'Método:',
                Payment.metodoPagoLabel(payment.metodoPago),
              ),
              if (payment.notas != null && payment.notas!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _detailRow('Notas:', payment.notas!),
              ],
              if (payment.recibidoPor != null) ...[
                pw.SizedBox(height: 8),
                _detailRow('Recibido por:', payment.recibidoPor!),
              ],
            ],
          ),
        ),

        pw.Spacer(),

        // ── Footer ───────────────────────────
        pw.Divider(color: _divider),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Gracias por su confianza',
            style: pw.TextStyle(
              fontSize: 11,
              fontStyle: pw.FontStyle.italic,
              color: _mutedText,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Dental Integral · Guatemala',
            style: pw.TextStyle(fontSize: 9, color: _mutedText),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  REPORT PDF
  // ══════════════════════════════════════════════════════════════

  /// Generates a summary report PDF and shares it.
  Future<void> generateAndShareReport(ReportData data) async {
    final pdf = pw.Document(
      title: 'Reporte Dental Integral',
      author: 'Dental Integral',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _clinicHeader(),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _mutedText),
          ),
        ),
        build: (context) => _buildReportContent(data),
      ),
    );

    final periodLabel =
        '${_dateFmt.format(data.from)}_${_dateFmt.format(data.to)}'
            .replaceAll('/', '-');
    await _shareDocument(pdf, 'reporte_$periodLabel.pdf');
  }

  List<pw.Widget> _buildReportContent(ReportData data) {
    final widgets = <pw.Widget>[];

    // ── Title ────────────────────────────
    widgets.add(pw.SizedBox(height: 10));
    widgets.add(pw.Divider(color: _primary, thickness: 2));
    widgets.add(pw.SizedBox(height: 10));
    widgets.add(
      pw.Center(
        child: pw.Text(
          'REPORTE DE LA CLÍNICA',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(pw.Center(
      child: pw.Text(
        'Período: ${_dateFmt.format(data.from)} — ${_dateFmt.format(data.to)}',
        style: pw.TextStyle(fontSize: 10, color: _mutedText),
      ),
    ));
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(pw.Center(
      child: pw.Text(
        'Generado: ${_dateTimeFmt.format(DateTime.now())}',
        style: pw.TextStyle(fontSize: 9, color: _mutedText),
      ),
    ));
    widgets.add(pw.SizedBox(height: 16));

    // ── KPIs row ────────────────────────
    widgets.add(_kpiRow([
      _kpiBox('Ingresos totales', 'Q ${_currFmt.format(data.totalIngresos)}'),
      _kpiBox('Total citas', '${data.totalCitas}'),
      _kpiBox('Pacientes', '${data.totalPacientes}'),
      _kpiBox('Registros clínicos', '${data.totalRegistrosClinicos}'),
    ]));
    widgets.add(pw.SizedBox(height: 20));

    // ── Ingresos por método ──────────────
    widgets.add(_sectionTitle('Ingresos por método de pago'));
    widgets.add(pw.SizedBox(height: 6));
    final metodoLabels = {
      'efectivo': 'Efectivo',
      'tarjeta': 'Tarjeta',
      'transferencia': 'Transferencia',
    };
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: _divider),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          _tableHeaderRow(['Método', 'Monto']),
          ...data.ingresosPorMetodo.entries.map((e) => _tableRow([
                metodoLabels[e.key] ?? e.key,
                'Q ${_currFmt.format(e.value)}',
              ])),
          _tableRow(
            ['TOTAL', 'Q ${_currFmt.format(data.totalIngresos)}'],
            bold: true,
            bg: _bgLight,
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    // ── Citas por estado ─────────────────
    widgets.add(_sectionTitle('Citas por estado'));
    widgets.add(pw.SizedBox(height: 6));
    final estadoLabels = {
      'programada': 'Programada',
      'confirmada': 'Confirmada',
      'en_sala': 'En sala',
      'en_atencion': 'En atención',
      'completada': 'Completada',
      'cancelada': 'Cancelada',
      'no_asistio': 'No asistió',
    };
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: _divider),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          _tableHeaderRow(['Estado', 'Cantidad']),
          ...data.citasPorEstado.entries.map((e) => _tableRow([
                estadoLabels[e.key] ?? e.key,
                '${e.value}',
              ])),
          _tableRow(
            ['TOTAL', '${data.totalCitas}'],
            bold: true,
            bg: _bgLight,
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    // ── Top 10 tratamientos ──────────────
    if (data.tratamientosFrecuentes.isNotEmpty) {
      widgets.add(_sectionTitle('Tratamientos más frecuentes (Top 10)'));
      widgets.add(pw.SizedBox(height: 6));
      final top10 = data.tratamientosFrecuentes.entries
          .take(10)
          .toList();
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: _divider),
          columnWidths: {
            0: const pw.IntrinsicColumnWidth(),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            _tableHeaderRow(['#', 'Tratamiento', 'Cantidad']),
            ...top10.asMap().entries.map((e) => _tableRow([
                  '${e.key + 1}',
                  e.value.key,
                  '${e.value.value}',
                ])),
          ],
        ),
      );
      widgets.add(pw.SizedBox(height: 20));
    }

    // ── Productividad por odontólogo ─────
    if (data.productividadPorOdontologo.isNotEmpty) {
      widgets.add(_sectionTitle('Productividad por odontólogo'));
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: _divider),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            _tableHeaderRow(['Odontólogo', 'Citas', 'Ingresos']),
            ...data.productividadPorOdontologo.entries.map((e) => _tableRow([
                  e.key,
                  '${e.value.citas}',
                  'Q ${_currFmt.format(e.value.ingresos)}',
                ])),
          ],
        ),
      );
      widgets.add(pw.SizedBox(height: 20));
    }

    // ── Ingresos por día ─────────────────
    if (data.ingresosPorDia.isNotEmpty) {
      widgets.add(_sectionTitle('Ingresos por día'));
      widgets.add(pw.SizedBox(height: 6));
      final sortedDays = data.ingresosPorDia.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: _divider),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            _tableHeaderRow(['Fecha', 'Monto']),
            ...sortedDays.map((e) => _tableRow([
                  e.key,
                  'Q ${_currFmt.format(e.value)}',
                ])),
          ],
        ),
      );
    }

    return widgets;
  }

  // ══════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════════════

  pw.Widget _clinicHeader() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo placeholder (dental icon via unicode)
        pw.Container(
          width: 44,
          height: 44,
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'DI',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Dental Integral',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
            pw.Text(
              'Clínica Odontológica · Guatemala',
              style: pw.TextStyle(fontSize: 9, color: _mutedText),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _darkText,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, color: _darkText),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _detailRow(String label, String value,
      {bool bold = false, bool big = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: big ? 12 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: _darkText,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: big ? 14 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: bold ? _accent : _darkText,
          ),
        ),
      ],
    );
  }

  pw.Widget _kpiRow(List<pw.Widget> children) {
    return pw.Row(
      children: children
          .map((c) => pw.Expanded(child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 3),
                child: c,
              )))
          .toList(),
    );
  }

  pw.Widget _kpiBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, color: _mutedText),
          ),
        ],
      ),
    );
  }

  pw.TableRow _tableHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _primary),
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                child: pw.Text(
                  c,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ))
          .toList(),
    );
  }

  pw.TableRow _tableRow(List<String> cells,
      {bool bold = false, PdfColor? bg}) {
    return pw.TableRow(
      decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: pw.Text(
                  c,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: _darkText,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── File sharing ───────────────────────────────────────────────

  Future<void> _shareDocument(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: fileName,
      ),
    );
  }
}
