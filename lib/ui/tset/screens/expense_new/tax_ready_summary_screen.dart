import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/api/api_service.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/general_functions.dart';
import '../../../screens/disclaimer/disclaimer_widget.dart';

// ══════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════

class _ReportSummary {
  final int    invoiceCount;
  final double totalAmount;
  final double deductibleAmount;
  final double gstHstClaimable;
  final double estimatedTaxSavings;
  final int    needsReviewCount;
  final int    missingInfoCount;

  const _ReportSummary({
    required this.invoiceCount,
    required this.totalAmount,
    required this.deductibleAmount,
    required this.gstHstClaimable,
    required this.estimatedTaxSavings,
    required this.needsReviewCount,
    required this.missingInfoCount,
  });

  factory _ReportSummary.fromJson(Map<String, dynamic> j) => _ReportSummary(
    invoiceCount:        (j['invoiceCount']        as num?)?.toInt()    ?? 0,
    totalAmount:         (j['totalAmount']         as num?)?.toDouble() ?? 0,
    deductibleAmount:    (j['deductibleAmount']    as num?)?.toDouble() ?? 0,
    gstHstClaimable:     (j['gstHstClaimable']     as num?)?.toDouble() ?? 0,
    estimatedTaxSavings: (j['estimatedTaxSavings'] as num?)?.toDouble() ?? 0,
    needsReviewCount:    (j['needsReviewCount']    as num?)?.toInt()    ?? 0,
    missingInfoCount:    (j['missingInfoCount']    as num?)?.toInt()    ?? 0,
  );
}

class _ReportInvoice {
  final String  invoiceId;
  final String  vendorName;
  final String  invoiceDate;
  final double  totalAmount;
  final String  currency;
  final String  categoryName;
  final String  subcategoryName;
  final String? thumbnailUrl;
  final List<String> imageUrls;
  final bool    needsReview;
  final String  type;

  const _ReportInvoice({
    required this.invoiceId,
    required this.vendorName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.currency,
    required this.categoryName,
    required this.subcategoryName,
    this.thumbnailUrl,
    required this.imageUrls,
    required this.needsReview,
    required this.type,
  });

  factory _ReportInvoice.fromJson(Map<String, dynamic> j) => _ReportInvoice(
    invoiceId:       j['invoiceId']?.toString()       ?? '',
    vendorName:      j['vendorName']?.toString()      ?? '',
    invoiceDate:     j['invoiceDate']?.toString()     ?? '',
    totalAmount:     (j['totalAmount'] as num?)?.toDouble() ?? 0,
    currency:        j['currency']?.toString()        ?? '',
    categoryName:    j['categoryName']?.toString()    ?? '',
    subcategoryName: j['subcategoryName']?.toString() ?? '',
    thumbnailUrl:    j['thumbnailUrl']?.toString(),
    imageUrls:       (j['imageUrls'] as List<dynamic>? ?? [])
        .map((e) => e.toString()).toList(),
    needsReview:     j['needsReview'] == true,
    type:            j['type']?.toString() ?? '',
  );

  String get formattedDate {
    try {
      final p = invoiceDate.split('-');
      if (p.length != 3) return invoiceDate;
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[int.parse(p[1])-1]} ${p[2]}, ${p[0]}';
    } catch (_) { return invoiceDate; }
  }
}

class _ReportData {
  final String          from;
  final String          to;
  final String          type;
  final String          baseCurrency;
  final _ReportSummary  summary;
  final List<_ReportInvoice> invoices;

  const _ReportData({
    required this.from,
    required this.to,
    required this.type,
    required this.baseCurrency,
    required this.summary,
    required this.invoices,
  });

  factory _ReportData.fromJson(Map<String, dynamic> data) {
    final period = data['period'] as Map<String, dynamic>? ?? {};
    return _ReportData(
      from:         period['from']?.toString()       ?? '',
      to:           period['to']?.toString()         ?? '',
      type:         data['type']?.toString()         ?? '',
      baseCurrency: data['baseCurrency']?.toString() ?? '',
      summary:      _ReportSummary.fromJson(
          data['summary'] as Map<String, dynamic>? ?? {}),
      invoices:     (data['invoices'] as List<dynamic>? ?? [])
          .map((e) => _ReportInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════

class TaxReadySummaryScreen extends StatefulWidget {
  const TaxReadySummaryScreen({super.key});

  @override
  State<TaxReadySummaryScreen> createState() => _TaxReadySummaryScreenState();
}

class _TaxReadySummaryScreenState extends State<TaxReadySummaryScreen> {

  DateTime _fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _toDate   = DateTime(DateTime.now().year, 12, 31);
  String   _type     = 'BUSINESS';

  bool         _loading      = false;
  _ReportData? _report;
  bool         _generatingPdf = false;
  bool         _downloading   = false;
  String?      _cachedPdfPath;

  // ── Max image height = 60% of available page height
  // A4 available height with 36pt margins = 841.89 - 72 = 769.89
  static const double _maxImgHeight = 769.89 * 0.60; // ~461pt

  String _fmt(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(2)
          .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}, ${d.year}';
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String get _pdfCacheKey =>
      'report_${_isoDate(_fromDate)}_${_isoDate(_toDate)}_$_type.pdf';

  // ── API ───────────────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    setState(() { _loading = true; _report = null; _cachedPdfPath = null; });
    try {
      final response = await ApiService.get(
        context,
        Endpoints.EXPENSE_REPORTS,
        queryParams: {
          'from': _isoDate(_fromDate),
          'to':   _isoDate(_toDate),
          'type': _type,
        },
        showLoader: false,
      );
      if (response != null && response['result'] == '1') {
        setState(() {
          _report  = _ReportData.fromJson(response['data'] as Map<String, dynamic>);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) GeneralFunctions.showError(context,
            response?['message']?.toString() ?? 'Failed to fetch report.');
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) GeneralFunctions.showError(
          context, 'Something went wrong. Please try again.');
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked  = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate:  DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: WerlogColors.teal, onPrimary: Colors.white,
            onSurface: WerlogColors.textPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: WerlogColors.teal)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) _fromDate = picked; else _toDate = picked;
      _report = null; _cachedPdfPath = null;
    });
  }

  // ── PDF generation ────────────────────────────────────────────────────
  Future<void> _generatePdf() async {
    if (_report == null) return;

    await DisclaimerWidget.show(context, type: DisclaimerType.export);
    if (!mounted) return;

    setState(() => _generatingPdf = true);

    try {
      final pdf = pw.Document();
      final r   = _report!;

      // ── Load images ─────────────────────────────────────────────────
      // We store thumbnail and invoice images separately to label them
      // thumbnailCache: url -> ImageProvider (thumbnail only)
      // imageUrlsCache: url -> ImageProvider (invoice images only)
      final Map<String, pw.MemoryImage?> allImgCache = {};

      for (final inv in r.invoices) {
        // Collect thumbnail
        if (inv.thumbnailUrl != null) {
          final url = inv.thumbnailUrl!;
          if (!allImgCache.containsKey(url)) {
            allImgCache[url] = await _loadImage(url);
          }
        }
        // Collect invoice images (may overlap with thumbnail — deduplicated by map)
        for (final url in inv.imageUrls) {
          if (!allImgCache.containsKey(url)) {
            allImgCache[url] = await _loadImage(url);
          }
        }
      }

      // ── PDF colours ──────────────────────────────────────────────────
      final teal     = PdfColor.fromHex('1D9E75');
      final darkText = PdfColor.fromHex('1A1A2E');
      final grey     = PdfColor.fromHex('6B7280');
      final light    = PdfColor.fromHex('F0FAF7');
      final border   = PdfColor.fromHex('E5E7EB');
      final amber    = PdfColor.fromHex('D97706');

      final double pageW = PdfPageFormat.a4.availableWidth;

      // ── Page 1 — cover + summary ─────────────────────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) => [

          // Header banner
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: teal,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Werlog Report - ${r.type}',
                    style: pw.TextStyle(color: PdfColors.white,
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(
                    '${r.type}  |  ${_fmtDate(_fromDate)} to ${_fmtDate(_toDate)}',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Generated on ${_fmtDate(DateTime.now())}  |  Currency: ${r.baseCurrency}',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text('Summary',
              style: pw.TextStyle(fontSize: 16,
                  fontWeight: pw.FontWeight.bold, color: darkText)),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: border, width: 0.5),
            children: [
              _pdfHeaderRow(['Metric', 'Value'], teal),
              _pdfDataRow(['Total Invoices',        '${r.summary.invoiceCount}'],           light,           border),
              _pdfDataRow(['Total Amount',           _fmt(r.summary.totalAmount)],           PdfColors.white, border),
              _pdfDataRow(['Deductible Amount',      _fmt(r.summary.deductibleAmount)],      light,           border),
              _pdfDataRow(['GST/HST Claimable',      _fmt(r.summary.gstHstClaimable)],       PdfColors.white, border),
              _pdfDataRow(['Estimated Tax Savings',  _fmt(r.summary.estimatedTaxSavings)],   light,           border),
            ],
          ),

          pw.SizedBox(height: 20),

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('FFF9E6'),
              border: pw.Border.all(
                  color: PdfColor.fromHex('FCD34D'), width: 0.8),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'DISCLAIMER: This export reflects data entered or confirmed in Werlog. '
                  'It does not constitute tax, legal, or accounting advice. '
                  'Estimates are for informational purposes only. '
                  'Consult a qualified professional before filing.',
              style: pw.TextStyle(
                  fontSize: 8, color: PdfColor.fromHex('92400E')),
            ),
          ),

          pw.SizedBox(height: 24),

          pw.Text('Invoice Details',
              style: pw.TextStyle(fontSize: 16,
                  fontWeight: pw.FontWeight.bold, color: darkText)),
          pw.SizedBox(height: 10),
        ],
      ));

      // ── One MultiPage per invoice ─────────────────────────────────────
      for (final inv in r.invoices) {

        // Separate thumbnail from invoice images
        final hasThumbnail   = inv.thumbnailUrl != null &&
            allImgCache[inv.thumbnailUrl] != null;
        // Invoice images excluding the thumbnail URL to avoid duplication
        final invoiceImgUrls = inv.imageUrls
            .where((u) => u != inv.thumbnailUrl)
            .where((u) => allImgCache[u] != null)
            .toList();

        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin:     const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) => [

            // ── Invoice header ──────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: light,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: border, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(inv.vendorName,
                            style: pw.TextStyle(fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            '${inv.categoryName}  |  ${inv.subcategoryName}',
                            style: pw.TextStyle(
                                fontSize: 9, color: grey)),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                            '${inv.currency} ${inv.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: teal)),
                        pw.SizedBox(height: 3),
                        pw.Text(inv.formattedDate,
                            style: pw.TextStyle(
                                fontSize: 9, color: grey)),
                      ]),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // ── Badges ──────────────────────────────────────────────────
            pw.Row(children: [
              _pdfBadge('Type: ${inv.type}', teal),
              if (inv.needsReview) ...[
                pw.SizedBox(width: 8),
                _pdfBadge('Needs Review', amber),
              ],
            ]),

            pw.SizedBox(height: 14),

            // ── Thumbnail section ────────────────────────────────────────
            if (hasThumbnail) ...[
              _pdfSectionLabel('Thumbnail', darkText, teal),
              pw.SizedBox(height: 6),
              _pdfImageBlock(
                allImgCache[inv.thumbnailUrl!]!,
                pageW,
                _maxImgHeight,
              ),
              pw.SizedBox(height: 14),
            ],

            // ── Invoice images section ───────────────────────────────────
            if (invoiceImgUrls.isNotEmpty) ...[
              _pdfSectionLabel(
                  'Invoice Images (${invoiceImgUrls.length})',
                  darkText, teal),
              pw.SizedBox(height: 6),
              ...invoiceImgUrls.asMap().entries.map((e) {
                final idx = e.key + 1;
                final url = e.value;
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Per-image label
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('Image $idx of ${invoiceImgUrls.length}',
                          style: pw.TextStyle(
                              fontSize: 8, color: grey,
                              fontStyle: pw.FontStyle.italic)),
                    ),
                    _pdfImageBlock(
                      allImgCache[url]!,
                      pageW,
                      _maxImgHeight,
                    ),
                    pw.SizedBox(height: 12),
                  ],
                );
              }),
            ],

            // ── No images notice ─────────────────────────────────────────
            if (!hasThumbnail && invoiceImgUrls.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F9FAFB'),
                  border: pw.Border.all(color: border, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text('No images available for this invoice.',
                    style: pw.TextStyle(fontSize: 9, color: grey)),
              ),

            pw.SizedBox(height: 8),
            pw.Divider(color: border, thickness: 0.5),
          ],
        ));
      }

      // ── Save ──────────────────────────────────────────────────────────
      final pdfFile = File('${Directory.systemTemp.path}/$_pdfCacheKey');
      await pdfFile.writeAsBytes(await pdf.save());

      setState(() {
        _generatingPdf = false;
        _cachedPdfPath = pdfFile.path;
      });

    } catch (e) {
      setState(() => _generatingPdf = false);
      if (mounted) GeneralFunctions.showError(
          context, 'Failed to generate PDF: $e');
    }
  }

  // ── Load single image from network ───────────────────────────────────
  Future<pw.MemoryImage?> _loadImage(String url) async {
    try {
      final resp = await http.get(Uri.parse(ApiService.baseImgUrl + url));
      if (resp.statusCode == 200) return pw.MemoryImage(resp.bodyBytes);
    } catch (_) {}
    return null;
  }

  // ── PDF image block: max 60% page height, full width, no crop ────────
  pw.Widget _pdfImageBlock(
      pw.MemoryImage img, double pageW, double maxH) {
    return pw.ConstrainedBox(
      constraints: pw.BoxConstraints(
        maxWidth:  pageW,
        maxHeight: maxH,
      ),
      child: pw.Image(img, fit: pw.BoxFit.contain),
    );
  }

  // ── Section label with left accent bar ───────────────────────────────
  pw.Widget _pdfSectionLabel(
      String label, PdfColor textColor, PdfColor accentColor) {
    return pw.Row(children: [
      pw.Container(
        width: 3, height: 14,
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: pw.BorderRadius.circular(2),
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Text(label,
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: textColor)),
    ]);
  }

  // ── PDF table helpers ─────────────────────────────────────────────────
  pw.TableRow _pdfHeaderRow(List<String> cells, PdfColor bg) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: cells.map((c) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(c,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        )).toList(),
      );

  pw.TableRow _pdfDataRow(
      List<String> cells, PdfColor bg, PdfColor border) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: cells.map((c) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(c, style: const pw.TextStyle(fontSize: 10)),
        )).toList(),
      );

  pw.Widget _pdfBadge(String label, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(label,
        style: pw.TextStyle(fontSize: 9,
            color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
  );

  // ── View PDF in-app ───────────────────────────────────────────────────
  void _viewPdf() {
    if (_cachedPdfPath == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PdfViewerScreen(path: _cachedPdfPath!),
    ));
  }

  // ── Download PDF ──────────────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    if (_cachedPdfPath == null) return;
    setState(() => _downloading = true);
    try {
      final bytes = await File(_cachedPdfPath!).readAsBytes();
      File? savedFile;

      if (Platform.isAndroid) {
        savedFile = await _downloadAndroid(bytes);
      } else {
        final docsDir = Directory(
            '${Directory.systemTemp.path}/../../Documents');
        await docsDir.create(recursive: true);
        savedFile = File('${docsDir.path}/$_pdfCacheKey');
        await savedFile.writeAsBytes(bytes, flush: true);
      }

      setState(() => _downloading = false);

      if (mounted && savedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved: $_pdfCacheKey',
              style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 13)),
          backgroundColor: WerlogColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      setState(() => _downloading = false);
      debugPrint('Download error: $e');
      if (mounted) GeneralFunctions.showError(
          context, 'Download failed: $e');
    }
  }

  Future<File> _downloadAndroid(Uint8List bytes) async {
    final tempFile = File('${Directory.systemTemp.path}/$_pdfCacheKey');
    await tempFile.writeAsBytes(bytes, flush: true);

    const downloadPath = '/storage/emulated/0/Download';
    final destFile = File('$downloadPath/$_pdfCacheKey');

    try {
      final dir = Directory(downloadPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      await destFile.writeAsBytes(bytes, flush: true);
      if (await destFile.exists() && await destFile.length() > 0) {
        return destFile;
      }
    } catch (e) {
      debugPrint('Direct Downloads write failed: $e');
    }

    try {
      final extDir = Directory(
          '/storage/emulated/0/Android/data/com.app.werlog/files/Download');
      await extDir.create(recursive: true);
      final fallback = File('${extDir.path}/$_pdfCacheKey');
      await fallback.writeAsBytes(bytes, flush: true);
      return fallback;
    } catch (_) {}

    return tempFile;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                const SizedBox(height: 16),
                _buildFilterCard(),
                const SizedBox(height: 14),
                if (_loading)
                  _buildLoadingState()
                else if (_report != null) ...[
                  _buildSummaryCard(),
                  const SizedBox(height: 14),
                  _buildInvoiceList(),
                  const SizedBox(height: 14),
                  _buildPdfSection(),
                ],
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAppBar() => Container(
    color: WerlogColors.surface,
    padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: WerlogColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      const Expanded(child: Text('Expense Report',
          textAlign: TextAlign.center,
          style: WerlogTextStyles.pageTitle)),
      const SizedBox(width: 40),
    ]),
  );

  Widget _buildFilterCard() => Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.tune_rounded,
              size: 14, color: WerlogColors.teal),
        ),
        const SizedBox(width: 8),
        const Text('Report Filters', style: WerlogTextStyles.sectionTitle),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        const Text('Type', style: WerlogTextStyles.captionSmall),
        const SizedBox(width: 12),
        Expanded(child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: WerlogColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: WerlogColors.borderLight),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            _FilterTab(label: 'Personal', selected: _type == 'PERSONAL',
                onTap: () => setState(() {
                  _type = 'PERSONAL'; _report = null; _cachedPdfPath = null;
                })),
            _FilterTab(label: 'Business', selected: _type == 'BUSINESS',
                onTap: () => setState(() {
                  _type = 'BUSINESS'; _report = null; _cachedPdfPath = null;
                })),
          ]),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _DatePickerField(
            label: 'From', date: _fromDate,
            onTap: () => _pickDate(isFrom: true))),
        const SizedBox(width: 10),
        Expanded(child: _DatePickerField(
            label: 'To', date: _toDate,
            onTap: () => _pickDate(isFrom: false))),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _fetchReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: WerlogColors.teal,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_rounded, size: 16, color: Colors.white),
            SizedBox(width: 7),
            Text('Generate Report',
                style: TextStyle(fontFamily: 'DMSans', fontSize: 14,
                    fontWeight: FontWeight.w500, color: Colors.white)),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildLoadingState() => Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(24),
    child: const Column(children: [
      CircularProgressIndicator(color: WerlogColors.teal, strokeWidth: 2.5),
      SizedBox(height: 14),
      Text('Fetching report data...', style: WerlogTextStyles.captionSmall),
    ]),
  );

  Widget _buildSummaryCard() {
    final s = _report!.summary;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1D9E75), Color(0xFF0F6B50)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1D9E75).withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_report!.type} Summary',
              style: const TextStyle(fontFamily: 'DMSans', fontSize: 15,
                  fontWeight: FontWeight.w600, color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(
                '${s.invoiceCount} Invoice${s.invoiceCount == 1 ? '' : 's'}',
                style: const TextStyle(fontFamily: 'DMSans', fontSize: 10,
                    fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('${_fmtDate(_fromDate)} to ${_fmtDate(_toDate)}',
            style: TextStyle(fontFamily: 'DMSans', fontSize: 11,
                color: Colors.white.withOpacity(0.6))),
        const SizedBox(height: 14),
        Divider(color: Colors.white.withOpacity(0.2), height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _GreenKpi(label: 'Total Amount', value: _fmt(s.totalAmount)),
          _GreenDivider(),
          _GreenKpi(label: 'Deductible',   value: _fmt(s.deductibleAmount)),
          _GreenDivider(),
          _GreenKpi(label: 'GST/HST',      value: _fmt(s.gstHstClaimable)),
        ]),
        const SizedBox(height: 14),
        Divider(color: Colors.white.withOpacity(0.2), height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _GreenKpi(label: 'Est. Savings', value: _fmt(s.estimatedTaxSavings)),
          _GreenDivider(),
          _GreenKpi(label: 'Needs Review', value: '${s.needsReviewCount}',
              valueColor: s.needsReviewCount > 0
                  ? const Color(0xFFFFD580) : Colors.white),
          _GreenDivider(),
          _GreenKpi(label: 'Missing Info', value: '${s.missingInfoCount}',
              valueColor: s.missingInfoCount > 0
                  ? const Color(0xFFFFD580) : Colors.white),
        ]),
      ]),
    );
  }

  Widget _buildInvoiceList() {
    final invoices = _report!.invoices;
    if (invoices.isEmpty) return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: const Center(child: Text('No invoices found for this period.',
          style: WerlogTextStyles.captionSmall)),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Invoices', style: WerlogTextStyles.sectionTitle),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(6)),
          child: Text('${invoices.length}',
              style: WerlogTextStyles.captionSmall.copyWith(
                  color: WerlogColors.teal, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 10),
      ...invoices.map((inv) => _InvoiceCard(inv: inv, fmt: _fmt)),
    ]);
  }

  Widget _buildPdfSection() => Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: WerlogColors.coralSurface,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.picture_as_pdf_rounded,
              size: 14, color: WerlogColors.coral),
        ),
        const SizedBox(width: 8),
        const Text('Export Report', style: WerlogTextStyles.sectionTitle),
      ]),
      const SizedBox(height: 6),
      const Text(
        'Generate a PDF with all invoice details and images attached.',
        style: WerlogTextStyles.captionSmall,
      ),
      const SizedBox(height: 14),
      if (_cachedPdfPath == null) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generatingPdf ? null : _generatePdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: WerlogColors.coral,
              disabledBackgroundColor: WerlogColors.coral.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _generatingPdf
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Generating PDF...',
                  style: TextStyle(fontFamily: 'DMSans',
                      fontSize: 14, color: Colors.white)),
            ])
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.picture_as_pdf_rounded,
                  size: 16, color: Colors.white),
              SizedBox(width: 7),
              Text('Generate PDF Report',
                  style: TextStyle(fontFamily: 'DMSans',
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ]),
          ),
        ),
      ] else ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WerlogColors.tealSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: WerlogColors.teal.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: WerlogColors.teal, size: 18),
            const SizedBox(width: 10),
            const Expanded(child: Text('PDF ready!',
                style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
                    fontWeight: FontWeight.w500, color: WerlogColors.teal))),
            GestureDetector(
              onTap: () => setState(() { _cachedPdfPath = null; }),
              child: const Icon(Icons.refresh_rounded,
                  size: 16, color: WerlogColors.teal),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _viewPdf,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: WerlogColors.teal),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.visibility_outlined, size: 15, color: WerlogColors.teal),
              SizedBox(width: 6),
              Text('View', style: TextStyle(fontFamily: 'DMSans',
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: WerlogColors.teal)),
            ]),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: _downloading ? null : _downloadPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: WerlogColors.teal,
              disabledBackgroundColor: WerlogColors.teal.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _downloading
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.download_rounded, size: 15, color: Colors.white),
              SizedBox(width: 6),
              Text('Download', style: TextStyle(fontFamily: 'DMSans',
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: Colors.white)),
            ]),
          )),
        ]),
      ],
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  PDF VIEWER
// ══════════════════════════════════════════════════════════════════════

class _PdfViewerScreen extends StatelessWidget {
  final String path;
  const _PdfViewerScreen({required this.path});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(children: [
        PdfPreview(
          build: (_) async => File(path).readAsBytes(),
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          pdfFileName: path.split('/').last,
        ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  LOCAL WIDGETS
// ══════════════════════════════════════════════════════════════════════

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.selected,
    required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? WerlogColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : WerlogColors.textTertiary,
            )),
      ),
    ),
  );
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerField({required this.label, required this.date,
    required this.onTap});

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WerlogColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded,
            size: 13, color: WerlogColors.textTertiary),
        const SizedBox(width: 7),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: WerlogTextStyles.caption),
            Text(_fmt(date),
                style: WerlogTextStyles.captionSmall.copyWith(
                    color: WerlogColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ],
        )),
      ]),
    ),
  );
}

class _GreenKpi extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _GreenKpi({required this.label, required this.value,
    this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'DMSans', fontSize: 10,
          color: Colors.white.withOpacity(0.65))),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
          fontWeight: FontWeight.w600, color: valueColor ?? Colors.white)),
    ]),
  );
}

class _GreenDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5, height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: Colors.white.withOpacity(0.2),
  );
}

class _InvoiceCard extends StatelessWidget {
  final _ReportInvoice inv;
  final String Function(double) fmt;
  const _InvoiceCard({required this.inv, required this.fmt});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: WerlogColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: WerlogColors.border, width: 0.8),
    ),
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: WerlogColors.tealSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WerlogColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: inv.thumbnailUrl != null
            ? Image.network(
          ApiService.baseImgUrl + inv.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.receipt_rounded,
              color: WerlogColors.teal, size: 20),
        )
            : const Icon(Icons.receipt_rounded,
            color: WerlogColors.teal, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(inv.vendorName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: WerlogTextStyles.txTitle.copyWith(fontSize: 13))),
            Text(fmt(inv.totalAmount),
                style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                    fontWeight: FontWeight.w600, color: WerlogColors.teal)),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 10, color: WerlogColors.textTertiary),
            const SizedBox(width: 4),
            Text(inv.formattedDate, style: WerlogTextStyles.captionSmall),
            const SizedBox(width: 8),
            const Text('|', style: TextStyle(
                color: WerlogColors.textTertiary, fontSize: 10)),
            const SizedBox(width: 8),
            Expanded(child: Text(inv.subcategoryName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: WerlogTextStyles.captionSmall)),
          ]),
          if (inv.needsReview) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: WerlogColors.amberSurface,
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('Needs Review',
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: WerlogColors.amber)),
            ),
          ],
        ],
      )),
    ]),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: WerlogColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: WerlogColors.border, width: 0.8),
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
      blurRadius: 8, offset: const Offset(0, 2))],
);