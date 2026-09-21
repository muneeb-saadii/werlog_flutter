import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';
import '../../../core/utils/shared_pref_helper.dart';
import '../../../core/widgets/plan_restriction_dialog.dart';
import '../../tset/screens/camera_screen_new.dart'; // for CameraUploadService

// ══════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════

enum _MatchStatus { matched, notMatched, ambiguous }

class _BankTransaction {
  final String? date;
  final double  amount;
  final String  description;
  final _MatchStatus status;
  final String? invoiceId;
  final String? vendorName;
  final List<Map<String, dynamic>> candidates;

  const _BankTransaction({
    this.date,
    required this.amount,
    required this.description,
    required this.status,
    this.invoiceId,
    this.vendorName,
    this.candidates = const [],
  });

  factory _BankTransaction.fromJson(Map<String, dynamic> j) {
    // ── Status ─────────────────────────────────────────────────────────
    _MatchStatus status;
    try {
      final s = j['status']?.toString().toUpperCase() ?? '';
      status = s == 'MATCHED'
          ? _MatchStatus.matched
          : s == 'AMBIGUOUS'
          ? _MatchStatus.ambiguous
          : _MatchStatus.notMatched;
    } catch (_) {
      status = _MatchStatus.notMatched;
    }

    // ── Matched invoice ────────────────────────────────────────────────
    String? vendorName;
    String? invoiceId;
    try {
      final matched = j['matched'];
      if (matched is Map) {
        vendorName = matched['vendorName']?.toString();
        invoiceId  = matched['invoiceId']?.toString();
      }
    } catch (_) {}

    // ── Candidates ─────────────────────────────────────────────────────
    List<Map<String, dynamic>> candidates = [];
    try {
      final raw = j['candidates'];
      if (raw is List) {
        candidates = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}

    return _BankTransaction(
      date:        j['txnDate']?.toString(),
      amount:      (j['txnAmount'] as num?)?.toDouble() ?? 0.0,
      description: j['txnDescription']?.toString() ?? '',
      status:      status,
      invoiceId:   invoiceId,
      vendorName:  vendorName,
      candidates:  candidates,
    );
  }
}

class _MatchSummary {
  final int    total;
  final int    matched;
  final int    notMatched;
  final int    ambiguous;
  final String baseCurrency;

  const _MatchSummary({
    this.total        = 0,
    this.matched      = 0,
    this.notMatched   = 0,
    this.ambiguous    = 0,
    this.baseCurrency = '',
  });

  /// Build from server-provided summary counts in data map
  factory _MatchSummary.fromApiData(Map<String, dynamic> data) {
    return _MatchSummary(
      total:        (data['transactions'] as num?)?.toInt() ?? 0,
      matched:      (data['matched']      as num?)?.toInt() ?? 0,
      notMatched:   (data['notMatched']   as num?)?.toInt() ?? 0,
      ambiguous:    (data['ambiguous']    as num?)?.toInt() ?? 0,
      baseCurrency: data['baseCurrency']?.toString() ?? '',
    );
  }

  /// Fallback: compute from transaction list
  factory _MatchSummary.fromTransactions(
      List<_BankTransaction> txns, {String baseCurrency = ''}) =>
      _MatchSummary(
        total:        txns.length,
        matched:      txns.where((t) => t.status == _MatchStatus.matched).length,
        notMatched:   txns.where((t) => t.status == _MatchStatus.notMatched).length,
        ambiguous:    txns.where((t) => t.status == _MatchStatus.ambiguous).length,
        baseCurrency: baseCurrency,
      );
}

// ══════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════

class BankStatementScreen extends StatefulWidget {
  const BankStatementScreen({super.key});

  @override
  State<BankStatementScreen> createState() => _BankStatementScreenState();
}

class _BankStatementScreenState extends State<BankStatementScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────
  File?   _selectedFile;
  String? _selectedFileName;
  int?    _selectedFileSize;

  DateTime _fromDate     = DateTime(DateTime.now().year, 1, 1);
  DateTime _toDate       = DateTime.now();
  String?  _paymentMethod;

  bool   _uploading = false;
  bool   _hasResult = false;
  bool   _hasError  = false;
  String _errorMsg  = '';

  List<_BankTransaction> _transactions = [];
  _MatchSummary          _summary      = const _MatchSummary();
  _MatchStatus?          _resultFilter;

  late final AnimationController _successCtrl;
  late final Animation<double>   _successScale;

  static const List<String?> _paymentMethods =
  [null, 'CASH', 'DEBIT_CARD', 'CREDIT_CARD'];
  static const List<String> _pmLabels =
  ['All methods', 'Cash', 'Debit card', 'Credit card'];

  // ── Init / dispose ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Formatters ──────────────────────────────────────────────────────────
  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fmtAmount(double v) =>
      '${GeneralFunctions.currencySymbol}${v.toStringAsFixed(2)}';

  // ── File picker ─────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.first;
    if (pf.path == null) return;
    setState(() {
      _selectedFile     = File(pf.path!);
      _selectedFileName = pf.name;
      _selectedFileSize = pf.size;
      _hasResult        = false;
      _hasError         = false;
      _transactions     = [];
    });
  }

  void _clearFile() => setState(() {
    _selectedFile     = null;
    _selectedFileName = null;
    _selectedFileSize = null;
    _hasResult        = false;
    _hasError         = false;
    _transactions     = [];
  });

  // ── Date pickers ────────────────────────────────────────────────────────
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
              style: TextButton.styleFrom(
                  foregroundColor: WerlogColors.teal)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) _fromDate = picked; else _toDate = picked;
    });
  }

  // ── Upload & match ──────────────────────────────────────────────────────
  Future<void> _upload() async {
    if (_selectedFile == null) return;
    setState(() {
      _uploading = true;
      _hasError  = false;
      _hasResult = false;
    });

    try {
      final service = CameraUploadService(
        baseUrl:   ApiService.baseUrl,
        authToken: SharedPrefHelper.getString(SharedPrefHelper.accessToken),
      );

      final Map<String, String> extraFields = {
        'from': _isoDate(_fromDate),
        'to':   _isoDate(_toDate),
        if (_paymentMethod != null) 'paymentMethod': _paymentMethod!,
      };

      final results = await service.uploadImages(
        context:     context,
        images:      [_selectedFile!],
        endpoint:    Endpoints.BANK_MATCH,
        fieldName:   'file',        // bank API uses 'file' (singular)
        extraFields: extraFields,
      );

      debugPrint('BANK MATCH success=${results.success}');
      debugPrint('BANK MATCH body=${results.body}');

      if (results.success) {
        // ── Parse response ────────────────────────────────────────────
        try {
          final body = jsonDecode(results.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>? ?? {};

          // Summary comes from server counts
          _summary = _MatchSummary.fromApiData(data);

          // Rows under data.rows
          final rawRows = data['rows'];
          if (rawRows is List) {
            _transactions = rawRows
                .whereType<Map>()
                .map((e) => _BankTransaction.fromJson(
                Map<String, dynamic>.from(e)))
                .toList();
          } else {
            _transactions = [];
          }

          setState(() { _hasResult = true; _uploading = false; });
          await _successCtrl.forward(from: 0);

        } catch (parseError) {
          debugPrint('Bank match parse error: $parseError');
          setState(() {
            _uploading = false;
            _hasError  = true;
            _errorMsg  =
            'Received an unexpected response format. Please try again.';
          });
        }

      } else {
        // ── Error handling — mirrors _openBottomSheet pattern ─────────
        Map<String, dynamic>? errorBody;
        try {
          errorBody = jsonDecode(results.body) as Map<String, dynamic>?;
        } catch (_) {}

        final errorCode    = errorBody?['error']?.toString()   ?? '';
        final errorMessage = errorBody?['message']?.toString() ??
            'Upload failed. Please try again.';

        if (errorCode == 'PLAN_RESTRICTION') {
          setState(() => _uploading = false);
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PlanRestrictionDialog(
              message: errorMessage,
              onViewPlans: () => Navigator.pop(context),
              onViewUsage: () => Navigator.pop(context),
              onCancel:    () => Navigator.pop(context),
            ),
          );
        } else {
          setState(() {
            _uploading = false;
            _hasError  = true;
            _errorMsg  = errorMessage;
          });
        }
      }

    } catch (e) {
      debugPrint('Bank match error: $e');
      setState(() {
        _uploading = false;
        _hasError  = true;
        _errorMsg  = 'Something went wrong. Please try again.';
      });
    }
  }

  // ── Filtered list ───────────────────────────────────────────────────────
  List<_BankTransaction> get _filtered => _resultFilter == null
      ? _transactions
      : _transactions.where((t) => t.status == _resultFilter).toList();

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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                const SizedBox(height: 16),
                _buildHeroBanner(),
                const SizedBox(height: 16),
                _buildFileCard(),
                const SizedBox(height: 12),
                _buildFiltersCard(),
                const SizedBox(height: 12),
                _buildUploadButton(),
                if (_hasError) ...[
                  const SizedBox(height: 12),
                  _buildErrorCard(),
                ],
                if (_hasResult) ...[
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  _buildResultList(),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────
  Widget _buildAppBar() => Container(
    color: WerlogColors.surface,
    padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: WerlogColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      const Expanded(
        child: Text('Bank Statement Match',
            textAlign: TextAlign.center,
            style: WerlogTextStyles.pageTitle),
      ),
      const SizedBox(width: 44),
    ]),
  );

  // ── Hero banner ──────────────────────────────────────────────────────────
  Widget _buildHeroBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0F2A2E), Color(0xFF1D9E75)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: WerlogColors.teal.withOpacity(0.25),
          blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.account_balance_rounded,
            color: Colors.white, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reconcile Expenses',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 15,
                  fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'Upload your bank statement PDF and we\'ll automatically '
                'match transactions to your saved expenses.',
            style: TextStyle(fontFamily: 'DMSans', fontSize: 11,
                color: Colors.white.withOpacity(0.72), height: 1.5),
          ),
        ],
      )),
    ]),
  );

  // ── File card ────────────────────────────────────────────────────────────
  Widget _buildFileCard() {
    final hasFile = _selectedFile != null;
    return Container(
      decoration: _cardDeco(),
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
          const Text('Bank Statement PDF',
              style: WerlogTextStyles.sectionTitle),
          const Spacer(),
          if (hasFile)
            GestureDetector(
              onTap: _clearFile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WerlogColors.coralSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: WerlogColors.coral.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.close_rounded,
                      size: 11, color: WerlogColors.coral),
                  SizedBox(width: 3),
                  Text('Remove',
                      style: TextStyle(fontFamily: 'DMSans',
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: WerlogColors.coral)),
                ]),
              ),
            ),
        ]),

        const SizedBox(height: 12),

        // Empty — picker zone
        if (!hasFile)
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: WerlogColors.tealSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: WerlogColors.teal.withOpacity(0.3),
                    width: 1.2),
              ),
              child: Column(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: WerlogColors.teal.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: WerlogColors.teal, size: 26),
                ),
                const SizedBox(height: 12),
                const Text('Tap to select PDF',
                    style: TextStyle(fontFamily: 'DMSans',
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: WerlogColors.teal)),
                const SizedBox(height: 4),
                Text('Bank statement in PDF format only',
                    style: WerlogTextStyles.captionSmall.copyWith(
                        color: WerlogColors.teal.withOpacity(0.7))),
              ]),
            ),
          ),

        // File selected
        if (hasFile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: WerlogColors.teal.withOpacity(0.25)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: WerlogColors.coral.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: WerlogColors.coral, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedFileName ?? '',
                      style: WerlogTextStyles.txTitle.copyWith(
                          fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    _selectedFileSize != null
                        ? _fmtSize(_selectedFileSize!)
                        : 'PDF file',
                    style: WerlogTextStyles.captionSmall,
                  ),
                ],
              )),
              const Icon(Icons.check_circle_rounded,
                  color: WerlogColors.teal, size: 20),
            ]),
          ),
      ]),
    );
  }

  // ── Filters card ──────────────────────────────────────────────────────────
  Widget _buildFiltersCard() => Container(
    decoration: _cardDeco(),
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
        const Text('Filters', style: WerlogTextStyles.sectionTitle),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: WerlogColors.tealSurface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text('Optional',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 9,
                  color: WerlogColors.teal, fontWeight: FontWeight.w500)),
        ),
      ]),

      const SizedBox(height: 12),

      Row(children: [
        Expanded(child: _DateTile(
          label: 'From', date: _fromDate,
          onTap: () => _pickDate(isFrom: true),
        )),
        const SizedBox(width: 10),
        Expanded(child: _DateTile(
          label: 'To', date: _toDate,
          onTap: () => _pickDate(isFrom: false),
        )),
      ]),

      const SizedBox(height: 12),

      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Payment Method',
            style: WerlogTextStyles.captionSmall.copyWith(
                color: WerlogColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(_paymentMethods.length, (i) {
            final pm       = _paymentMethods[i];
            final label    = _pmLabels[i];
            final selected = _paymentMethod == pm;
            return GestureDetector(
              onTap: () => setState(() => _paymentMethod = pm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? WerlogColors.teal
                      : WerlogColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? WerlogColors.teal
                        : WerlogColors.border,
                  ),
                ),
                child: Text(label,
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? Colors.white : WerlogColors.textSecondary,
                    )),
              ),
            );
          }),
        ),
      ]),
    ]),
  );

  // ── Upload button ─────────────────────────────────────────────────────────
  Widget _buildUploadButton() {
    final canUpload = _selectedFile != null && !_uploading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canUpload ? _upload : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: WerlogColors.teal,
          disabledBackgroundColor: WerlogColors.teal.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _uploading
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5)),
          SizedBox(width: 10),
          Text('Matching transactions...',
              style: TextStyle(fontFamily: 'DMSans',
                  fontSize: 14, color: Colors.white)),
        ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.compare_arrows_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            _selectedFile == null
                ? 'Select a PDF first'
                : 'Match Bank Statement',
            style: const TextStyle(fontFamily: 'DMSans',
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ]),
      ),
    );
  }

  // ── Error card ────────────────────────────────────────────────────────────
  Widget _buildErrorCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: WerlogColors.coralSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: WerlogColors.coral.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: WerlogColors.coral, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(_errorMsg,
          style: const TextStyle(fontFamily: 'DMSans',
              fontSize: 13, color: WerlogColors.coral, height: 1.4))),
    ]),
  );

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() => ScaleTransition(
    scale: _successScale,
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1D9E75), Color(0xFF0F6B50)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: WerlogColors.teal.withOpacity(0.28),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Match Results',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 15,
                  fontWeight: FontWeight.w600, color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_summary.total} transaction${_summary.total == 1 ? '' : 's'}'
                  '${_summary.baseCurrency.isNotEmpty ? ' · ${_summary.baseCurrency}' : ''}',
              style: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 10, color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]),

        const SizedBox(height: 14),
        Divider(color: Colors.white.withOpacity(0.2), height: 1),
        const SizedBox(height: 14),

        Row(children: [
          _StatKpi(label: 'Matched',
              value: '${_summary.matched}',
              color: const Color(0xFF90EEC4)),
          _StatDivider(),
          _StatKpi(label: 'Unmatched',
              value: '${_summary.notMatched}',
              color: const Color(0xFFFFD580)),
          _StatDivider(),
          _StatKpi(label: 'Ambiguous',
              value: '${_summary.ambiguous}',
              color: const Color(0xFFFFAB80)),
        ]),
      ]),
    ),
  );

  // ── Result list ───────────────────────────────────────────────────────────
  Widget _buildResultList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // Filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          const Text('Transactions', style: WerlogTextStyles.sectionTitle),
          const SizedBox(width: 10),
          ...[null, _MatchStatus.matched,
            _MatchStatus.notMatched, _MatchStatus.ambiguous]
              .map((s) {
            final labels = {
              null:                    'All',
              _MatchStatus.matched:    'Matched',
              _MatchStatus.notMatched: 'Unmatched',
              _MatchStatus.ambiguous:  'Ambiguous',
            };
            final colors = {
              null:                    WerlogColors.teal,
              _MatchStatus.matched:    WerlogColors.teal,
              _MatchStatus.notMatched: WerlogColors.amber,
              _MatchStatus.ambiguous:  WerlogColors.coral,
            };
            final sel = _resultFilter == s;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _resultFilter = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel
                        ? colors[s]!.withOpacity(0.15)
                        : WerlogColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: sel
                          ? colors[s]!.withOpacity(0.5)
                          : WerlogColors.border,
                    ),
                  ),
                  child: Text(labels[s]!,
                      style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 10,
                        fontWeight: sel
                            ? FontWeight.w600 : FontWeight.w400,
                        color: sel
                            ? colors[s]! : WerlogColors.textTertiary,
                      )),
                ),
              ),
            );
          }),
        ]),
      ),

      const SizedBox(height: 10),

      if (_filtered.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDeco(),
          child: Center(child: Text(
            'No transactions match this filter.',
            style: WerlogTextStyles.captionSmall,
          )),
        )
      else
        ..._filtered.map((txn) => _TransactionCard(
            txn: txn, fmtAmount: _fmtAmount)),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════
//  SUB WIDGETS
// ══════════════════════════════════════════════════════════════════════

class _DateTile extends StatelessWidget {
  final String   label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date,
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
            Text(label,
                style: WerlogTextStyles.caption.copyWith(fontSize: 10)),
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

class _StatKpi extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatKpi({required this.label, required this.value,
    required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'DMSans', fontSize: 10,
          color: Colors.white.withOpacity(0.65))),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'DMSans', fontSize: 22,
          fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5, height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withOpacity(0.2),
  );
}

class _TransactionCard extends StatelessWidget {
  final _BankTransaction txn;
  final String Function(double) fmtAmount;
  const _TransactionCard({required this.txn, required this.fmtAmount});

  Color get _statusColor => switch (txn.status) {
    _MatchStatus.matched    => WerlogColors.teal,
    _MatchStatus.notMatched => WerlogColors.amber,
    _MatchStatus.ambiguous  => WerlogColors.coral,
  };

  IconData get _statusIcon => switch (txn.status) {
    _MatchStatus.matched    => Icons.check_circle_rounded,
    _MatchStatus.notMatched => Icons.remove_circle_outline_rounded,
    _MatchStatus.ambiguous  => Icons.help_outline_rounded,
  };

  String get _statusLabel => switch (txn.status) {
    _MatchStatus.matched    => 'Matched',
    _MatchStatus.notMatched => 'Unmatched',
    _MatchStatus.ambiguous  => 'Ambiguous',
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: WerlogColors.surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
          color: _statusColor.withOpacity(0.2), width: 0.8),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(children: [

      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [

          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(
                  txn.description.isNotEmpty
                      ? txn.description : 'Bank transaction',
                  style: WerlogTextStyles.txTitle.copyWith(fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
                Text(fmtAmount(txn.amount),
                    style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                if (txn.date != null) ...[
                  const Icon(Icons.calendar_today_rounded,
                      size: 10, color: WerlogColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(txn.date!,
                      style: WerlogTextStyles.captionSmall),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(fontFamily: 'DMSans',
                          fontSize: 9, fontWeight: FontWeight.w500,
                          color: _statusColor)),
                ),
              ]),
            ],
          )),
        ]),
      ),

      // Matched invoice
      if (txn.status == _MatchStatus.matched &&
          txn.vendorName != null) ...[
        Divider(color: WerlogColors.borderLight, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded,
                size: 12, color: WerlogColors.teal),
            const SizedBox(width: 6),
            Text('Matched to: ', style: WerlogTextStyles.captionSmall),
            Expanded(child: Text(txn.vendorName!,
                style: WerlogTextStyles.captionSmall.copyWith(
                    color: WerlogColors.teal,
                    fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ],

      // Ambiguous candidates
      if (txn.status == _MatchStatus.ambiguous &&
          txn.candidates.isNotEmpty) ...[
        Divider(color: WerlogColors.borderLight, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Possible matches:',
                  style: WerlogTextStyles.captionSmall.copyWith(
                      color: WerlogColors.coral)),
              const SizedBox(height: 4),
              ...txn.candidates.take(3).map((c) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(children: [
                  const Icon(Icons.arrow_right_rounded,
                      size: 14, color: WerlogColors.coral),
                  Expanded(child: Text(
                    c['vendorName']?.toString()
                        ?? c['invoiceId']?.toString()
                        ?? '-',
                    style: WerlogTextStyles.captionSmall.copyWith(
                        color: WerlogColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ]),
              )),
            ],
          ),
        ),
      ],
    ]),
  );
}

BoxDecoration _cardDeco() => BoxDecoration(
  color: WerlogColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: WerlogColors.border, width: 0.8),
  boxShadow: [BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8, offset: const Offset(0, 2))],
);