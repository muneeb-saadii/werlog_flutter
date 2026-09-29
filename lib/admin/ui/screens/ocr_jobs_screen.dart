import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/admin_api_service.dart';
import '../../core/api/admin_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  MODELS
// ═════════════════════════════════════════════════════════════════════════════

class OpsInvoice {
  final String  id;
  final String  userId;
  final String  fileUrl;
  final String  fileName;
  final String  mimeType;
  final int?    fileSizeBytes;
  final String  status;
  final String? vendorName;
  final String? invoiceDate;
  final double? totalAmount;
  final String  currency;
  final double? taxAmount;
  final double? confidenceScore;
  final String  type;          // PERSONAL | BUSINESS
  final String? paymentMethod;
  final String  createdAt;
  final List<Map<String, dynamic>> lineItems;
  final bool    autoCategorized;

  const OpsInvoice({
    required this.id,
    required this.userId,
    required this.fileUrl,
    required this.fileName,
    required this.mimeType,
    this.fileSizeBytes,
    required this.status,
    this.vendorName,
    this.invoiceDate,
    this.totalAmount,
    required this.currency,
    this.taxAmount,
    this.confidenceScore,
    required this.type,
    this.paymentMethod,
    required this.createdAt,
    required this.lineItems,
    required this.autoCategorized,
  });

  factory OpsInvoice.fromJson(Map<String, dynamic> j) {
    final items = (j['extractedData']?['line_items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return OpsInvoice(
      id:               j['id']?.toString()           ?? '',
      userId:           j['userId']?.toString()       ?? '',
      fileUrl:          j['fileUrl']?.toString()      ?? '',
      fileName:         j['fileName']?.toString()     ?? '',
      mimeType:         j['mimeType']?.toString()     ?? 'image/jpeg',
      fileSizeBytes:    (j['fileSizeBytes'] as num?)?.toInt(),
      status:           (j['status'] ?? '').toString().toUpperCase(),
      vendorName:       j['vendorName']?.toString(),
      invoiceDate:      j['invoiceDate']?.toString(),
      totalAmount:      (j['totalAmount'] as num?)?.toDouble(),
      currency:         j['currency']?.toString()     ?? 'USD',
      taxAmount:        (j['taxAmount'] as num?)?.toDouble(),
      confidenceScore:  (j['confidenceScore'] as num?)?.toDouble(),
      type:             (j['type'] ?? 'PERSONAL').toString().toUpperCase(),
      paymentMethod:    j['paymentMethod']?.toString(),
      createdAt:        j['createdAt']?.toString()    ?? '',
      lineItems:        items,
      autoCategorized:  j['autoCategorized'] == true,
    );
  }

  String get fullImageUrl =>
      fileUrl.startsWith('http') ? fileUrl : 'https://werlog.com$fileUrl';

  bool get isImage =>
      mimeType.startsWith('image/') ||
          fileUrl.toLowerCase().endsWith('.jpg') ||
          fileUrl.toLowerCase().endsWith('.jpeg') ||
          fileUrl.toLowerCase().endsWith('.png');

  String get shortId =>
      id.length > 8 ? '${id.substring(0, 4)}…${id.substring(id.length - 4)}' : id;

  String get fileSizeLabel {
    if (fileSizeBytes == null) return '';
    final kb = fileSizeBytes! / 1024;
    return kb < 1024 ? '${kb.toStringAsFixed(0)} KB' : '${(kb/1024).toStringAsFixed(1)} MB';
  }
}

class OcrJob {
  final String  id;
  final String  invoiceId;
  final String  userId;
  final String  engine;
  final String  status;   // PENDING | PROCESSING | FAILED | COMPLETED | DONE
  final int     attemptCount;
  final int?    durationMs;
  final String? errorMessage;
  final String  createdAt;
  final String? completedAt;
  final int     segmentCount;
  final bool    multiSegment;
  final String? mergeStrategy;
  final Map<String, dynamic> rawResponse;

  // Parsed from rawResponse
  final String? imageQuality;
  final double? overallConfidence;
  final String? primaryCategory;
  final String? subCategory;
  final double? categoryConfidence;
  final String? vendorName;
  final String? city;
  final String? country;
  final String? documentType;
  final double? grandTotal;
  final String? detectedCurrency;

  const OcrJob({
    required this.id,
    required this.invoiceId,
    required this.userId,
    required this.engine,
    required this.status,
    required this.attemptCount,
    this.durationMs,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    required this.segmentCount,
    required this.multiSegment,
    this.mergeStrategy,
    required this.rawResponse,
    this.imageQuality,
    this.overallConfidence,
    this.primaryCategory,
    this.subCategory,
    this.categoryConfidence,
    this.vendorName,
    this.city,
    this.country,
    this.documentType,
    this.grandTotal,
    this.detectedCurrency,
  });

  factory OcrJob.fromJson(Map<String, dynamic> j) {
    final raw = j['rawResponse'] as Map<String, dynamic>? ?? {};

    // Parse quality JSON string
    Map<String, dynamic> quality = {};
    try { quality = json.decode(raw['quality']?.toString() ?? '{}'); } catch (_) {}

    // Parse category JSON string
    Map<String, dynamic> category = {};
    try { category = json.decode(raw['category']?.toString() ?? '{}'); } catch (_) {}

    // Parse extracted JSON string
    Map<String, dynamic> extracted = {};
    try { extracted = json.decode(raw['extracted']?.toString() ?? '{}'); } catch (_) {}

    final vendor   = extracted['vendor']  as Map<String, dynamic>? ?? {};
    final totals   = extracted['totals']  as Map<String, dynamic>? ?? {};

    return OcrJob(
      id:               j['id']?.toString()           ?? '',
      invoiceId:        j['invoiceId']?.toString()    ?? '',
      userId:           j['userId']?.toString()       ?? '',
      engine:           j['engine']?.toString()       ?? '',
      status:           (j['status'] ?? '').toString().toUpperCase(),
      attemptCount:     (j['attemptCount'] as num?)?.toInt() ?? 1,
      durationMs:       (j['durationMs'] as num?)?.toInt(),
      errorMessage:     j['errorMessage']?.toString(),
      createdAt:        j['createdAt']?.toString()    ?? '',
      completedAt:      j['completedAt']?.toString(),
      segmentCount:     (j['segmentCount'] as num?)?.toInt() ?? 1,
      multiSegment:     j['multiSegment'] == true,
      mergeStrategy:    j['mergeStrategy']?.toString(),
      rawResponse:      raw,
      imageQuality:     quality['image_quality']?.toString(),
      overallConfidence:(quality['overall_confidence'] as num?)?.toDouble(),
      primaryCategory:  category['primary_category']?.toString()
          ?? extracted['expense_category']?['primary_category']?.toString(),
      subCategory:      category['sub_category']?.toString()
          ?? extracted['expense_category']?['sub_category']?.toString(),
      categoryConfidence:(category['confidence'] as num?)?.toDouble()
          ?? (extracted['expense_category']?['confidence'] as num?)?.toDouble(),
      vendorName:       vendor['store_name']?.toString(),
      city:             vendor['city']?.toString(),
      country:          vendor['country']?.toString(),
      documentType:     extracted['document_type']?.toString()
          ?? raw['document_type']?.toString(),
      grandTotal:       (totals['grand_total'] as num?)?.toDouble(),
      detectedCurrency: totals['currency']?.toString(),
    );
  }

  bool get isFailed     => status == 'FAILED';
  bool get isProcessing => status == 'PROCESSING';
  bool get isPending    => status == 'PENDING';
  bool get isDone       => status == 'COMPLETED' || status == 'DONE';

  String get durationLabel {
    if (durationMs == null) return '';
    if (durationMs! < 1000) return '${durationMs}ms';
    return '${(durationMs! / 1000).toStringAsFixed(1)}s';
  }

  String get shortId =>
      id.length > 8 ? '${id.substring(0, 4)}…${id.substring(id.length - 4)}' : id;
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═════════════════════════════════════════════════════════════════════════════

String _fmtDate(String? s) {
  if (s == null || s.isEmpty || s == 'null') return '—';
  try {
    final d = DateTime.parse(s);
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  } catch (_) { return s; }
}

String _relTime(String? s) {
  if (s == null || s.isEmpty) return '';
  try {
    final diff = DateTime.now().difference(DateTime.parse(s));
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) { return ''; }
}

// ═════════════════════════════════════════════════════════════════════════════
//  OPS SCREEN  (two-tab: OCR Jobs + Invoices)
// ═════════════════════════════════════════════════════════════════════════════

class OcrJobsScreen extends StatefulWidget {
  const OcrJobsScreen({super.key});

  @override
  State<OcrJobsScreen> createState() => _OcrJobsScreenState();
}

class _OcrJobsScreenState extends State<OcrJobsScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tab;

  // OCR Jobs
  bool          _jobsLoading = true;
  List<OcrJob>  _allJobs     = [];
  String        _jobFilter   = '';   // '' | PENDING | PROCESSING | FAILED | COMPLETED

  // Invoices
  bool            _invLoading = true;
  List<OpsInvoice> _allInv   = [];
  String          _invFilter  = '';
  final _invSearch = TextEditingController();
  String          _invQuery   = '';

  List<OcrJob> get _filteredJobs => _jobFilter.isEmpty
      ? _allJobs
      : _allJobs.where((j) => j.status == _jobFilter).toList();

  List<OpsInvoice> get _filteredInv {
    List<OpsInvoice> list = _invFilter.isEmpty
        ? _allInv
        : _allInv.where((i) => i.status == _invFilter).toList();
    if (_invQuery.isNotEmpty) {
      final q = _invQuery.toLowerCase();
      list = list.where((i) =>
      (i.vendorName ?? '').toLowerCase().contains(q) ||
          i.currency.toLowerCase().contains(q) ||
          i.type.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int get _failedCount => _allJobs.where((j) => j.isFailed).length;
  int get _pendingCount => _allJobs.where((j) => j.isPending).length;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _invSearch.addListener(() => setState(() => _invQuery = _invSearch.text.toLowerCase().trim()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchJobs();
      _fetchInvoices();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _invSearch.dispose();
    super.dispose();
  }

  // ── Fetch OCR jobs ─────────────────────────────────────────────────────────

  Future<void> _fetchJobs() async {
    setState(() => _jobsLoading = true);
    try {
      final resp = await AdminApiService.get(
        context, AdminEndpoints.adminOcrJobs,
        queryParams: {'page': '0', 'size': '50'},
        showLoader: false,
      );
      debugPrint('[OPS/Jobs] response keys => ${resp?.keys}');
      if (!mounted) return;
      if (resp != null) {
        final raw = resp['data'];
        final list = raw is List ? raw : (raw is Map ? raw['content'] ?? [] : []);
        _allJobs = (list as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(OcrJob.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[OPS/Jobs] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load OCR jobs');
    } finally {
      if (mounted) setState(() => _jobsLoading = false);
    }
  }

  // ── Fetch Invoices ─────────────────────────────────────────────────────────

  Future<void> _fetchInvoices() async {
    setState(() => _invLoading = true);
    try {
      final resp = await AdminApiService.get(
        context, AdminEndpoints.adminInvoices,
        queryParams: {'page': '0', 'size': '50'},
        showLoader: false,
      );
      debugPrint('[OPS/Invoices] response keys => ${resp?.keys}');
      if (!mounted) return;
      if (resp != null) {
        final raw = resp['data'];
        final list = raw is List ? raw : (raw is Map ? raw['content'] ?? [] : []);
        _allInv = (list as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(OpsInvoice.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[OPS/Invoices] error => $e');
      if (mounted) AdminApiService.showError(context, 'Failed to load invoices');
    } finally {
      if (mounted) setState(() => _invLoading = false);
    }
  }

  // ── Retry OCR job ──────────────────────────────────────────────────────────

  Future<void> _retryJob(OcrJob job) async {
    try {
      final resp = await AdminApiService.post(
          context, AdminEndpoints.adminOcrJobRetry(job.id), showLoader: false);
      debugPrint('[OPS/Jobs] retry ${job.id} => $resp');
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Retry queued for ${job.engine}');
      await _fetchJobs();
    } catch (e) {
      if (mounted) AdminApiService.showError(context, 'Retry failed');
    }
  }

  // ── Delete invoice ─────────────────────────────────────────────────────────

  Future<void> _deleteInvoice(OpsInvoice inv) async {
    try {
      await AdminApiService.delete(
          context, AdminEndpoints.adminInvoiceDelete(inv.id), showLoader: false);
      if (!mounted) return;
      AdminApiService.showSuccess(context, 'Invoice deleted');
      _allInv.removeWhere((i) => i.id == inv.id);
      setState(() {});
    } catch (e) {
      if (mounted) AdminApiService.showError(context, 'Delete failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _OpsHeader(
              failedCount:  _failedCount,
              pendingCount: _pendingCount,
              totalJobs:    _allJobs.length,
              totalInvoices:_allInv.length,
              onRefresh:    () { _fetchJobs(); _fetchInvoices(); },
              tab:          _tab,
            ),
            // Tab bar
            Container(
              color: AppColors.cardWhite,
              child: TabBar(
                controller: _tab,
                indicatorColor:  AppColors.accentGreen,
                indicatorWeight: 2.5,
                labelColor:      AppColors.darkGreen,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 13.5,
                    fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 13.5,
                    fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'OCR Jobs  (${_allJobs.length})'),
                  Tab(text: 'Invoices  (${_allInv.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _JobsTab(
                    loading:   _jobsLoading,
                    jobs:      _filteredJobs,
                    filter:    _jobFilter,
                    onFilter:  (f) => setState(() => _jobFilter = f),
                    onRefresh: _fetchJobs,
                    onRetry:   _retryJob,
                    onTap:     (j) => _pushJobDetail(j),
                  ),
                  _InvoicesTab(
                    loading:    _invLoading,
                    invoices:   _filteredInv,
                    filter:     _invFilter,
                    search:     _invSearch,
                    onFilter:   (f) => setState(() => _invFilter = f),
                    onRefresh:  _fetchInvoices,
                    onDelete:   _deleteInvoice,
                    onTap:      (i) => _pushInvoiceDetail(i),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _pushJobDetail(OcrJob job) {
    // Find linked invoice
    final invoice = _allInv.where((i) => i.id == job.invoiceId).firstOrNull;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => OcrJobDetailScreen(job: job, invoice: invoice)));
  }

  void _pushInvoiceDetail(OpsInvoice inv) {
    final job = _allJobs.where((j) => j.invoiceId == inv.id).firstOrNull;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => OpsInvoiceDetailScreen(
            invoice: inv, job: job,
            onDelete: () => _deleteInvoice(inv))));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OPS HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _OpsHeader extends StatelessWidget {
  final int failedCount, pendingCount, totalJobs, totalInvoices;
  final VoidCallback onRefresh;
  final TabController tab;

  const _OpsHeader({
    required this.failedCount, required this.pendingCount,
    required this.totalJobs,  required this.totalInvoices,
    required this.onRefresh,  required this.tab,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 18),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('OPS Centre', style: AppTextStyles.headerTitle),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          _Pill('$pendingCount pending', AppColors.suspendedBg,
              AppColors.suspendedText),
          if (failedCount > 0)
            _Pill('$failedCount failed', const Color(0xFFFBDEDA),
                const Color(0xFFB94040)),
          _Pill('$totalInvoices invoices', AppColors.activeBg,
              AppColors.activeText),
        ]),
      ])),
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle),
          child: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Pill(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: bg.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(
        fontFamily: 'DMSans', fontSize: 11.5,
        fontWeight: FontWeight.w600, color: fg)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  JOBS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _JobsTab extends StatelessWidget {
  final bool loading;
  final List<OcrJob> jobs;
  final String filter;
  final ValueChanged<String> onFilter;
  final VoidCallback onRefresh;
  final void Function(OcrJob) onRetry;
  final void Function(OcrJob) onTap;

  const _JobsTab({
    required this.loading, required this.jobs, required this.filter,
    required this.onFilter, required this.onRefresh,
    required this.onRetry, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _FilterRow(
        items: const [
          ('', 'All'), ('PENDING', 'Pending'), ('PROCESSING', 'Processing'),
          ('FAILED', 'Failed'), ('COMPLETED', 'Done'),
        ],
        selected: filter,
        onSelected: onFilter,
      ),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator(
            color: AppColors.accentGreen))
            : jobs.isEmpty
            ? const _EmptyState(icon: Icons.bolt_outlined,
            label: 'No OCR jobs')
            : RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: AppColors.accentGreen,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: jobs.length,
            itemBuilder: (_, i) => _JobCard(
              job:     jobs[i],
              onTap:   () => onTap(jobs[i]),
              onRetry: jobs[i].isFailed ? () => onRetry(jobs[i]) : null,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  JOB CARD
// ─────────────────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final OcrJob job;
  final VoidCallback onTap;
  final VoidCallback? onRetry;
  const _JobCard({required this.job, required this.onTap, this.onRetry});

  _StatusCfg get _cfg {
    switch (job.status) {
      case 'FAILED':
        return _StatusCfg(Icons.warning_amber_rounded,
            const Color(0xFFFBDEDA), const Color(0xFFB94040), 'Failed');
      case 'PROCESSING':
        return _StatusCfg(Icons.sync_rounded,
            AppColors.suspendedBg, AppColors.suspendedText, 'Processing');
      case 'PENDING':
        return _StatusCfg(Icons.schedule_rounded,
            AppColors.deletedBg, AppColors.textSecondary, 'Pending');
      default:
        return _StatusCfg(Icons.check_circle_outline_rounded,
            AppColors.activeBg, AppColors.activeText, 'Done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          border: Border.all(
            color: job.isFailed
                ? const Color(0xFFF0BDBA) : AppColors.divider,
            width: job.isFailed ? 1.2 : 0.8,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(children: [
              // Status icon
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: c.bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(c.icon, color: c.fg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  job.vendorName?.isNotEmpty == true
                      ? job.vendorName!
                      : 'Job ${job.shortId}',
                  style: AppTextStyles.nameBold.copyWith(fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(children: [
                  _Tag(job.engine),
                  const SizedBox(width: 6),
                  if (job.multiSegment) ...[
                    _Tag('${job.segmentCount} segs', amber: true),
                    const SizedBox(width: 6),
                  ],
                  if (job.durationLabel.isNotEmpty)
                    _Tag(job.durationLabel, green: true),
                ]),
              ])),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: c.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(c.label, style: TextStyle(
                    fontFamily: 'DMSans', fontSize: 11.5,
                    fontWeight: FontWeight.w700, color: c.fg)),
              ),
            ]),
          ),

          // Details row
          if (job.primaryCategory != null || job.imageQuality != null ||
              job.overallConfidence != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(68, 0, 14, 10),
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                if (job.primaryCategory != null)
                  _InfoChip(Icons.label_outline_rounded,
                      _fmtCategory(job.primaryCategory!)),
                if (job.imageQuality != null)
                  _InfoChip(_qualityIcon(job.imageQuality!), job.imageQuality!),
                if (job.overallConfidence != null)
                  _InfoChip(Icons.percent_rounded,
                      '${(job.overallConfidence! * 100).round()}%',
                      color: _confColor(job.overallConfidence!)),
              ]),
            ),

          // Error + retry
          if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
            const Divider(height: 1, indent: 14, endIndent: 14,
                color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: Color(0xFFB94040)),
                const SizedBox(width: 6),
                Expanded(child: Text(job.errorMessage!,
                    style: const TextStyle(fontFamily: 'DMSans', fontSize: 12,
                        color: Color(0xFFB94040)),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (onRetry != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.replay_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Retry', style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 12,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ]),
            ),
          ],

          // Footer: time + attempt count
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_relTime(job.createdAt),
                  style: AppTextStyles.footerNote.copyWith(fontSize: 11)),
              const Spacer(),
              if (job.attemptCount > 1)
                _Tag('attempt ${job.attemptCount}',
                    color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textSecondary),
            ]),
          ),
        ]),
      ),
    );
  }

  static String _fmtCategory(String s) =>
      s.replaceAll('-', ' ').split(' ').map((w) =>
      w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  static IconData _qualityIcon(String q) {
    switch (q.toUpperCase()) {
      case 'CLEAR':          return Icons.hd_rounded;
      case 'GOOD':           return Icons.image_rounded;
      case 'LOW_RESOLUTION': return Icons.image_not_supported_outlined;
      default:               return Icons.photo_outlined;
    }
  }

  static Color _confColor(double v) {
    if (v >= 0.9) return AppColors.activeText;
    if (v >= 0.7) return AppColors.suspendedText;
    return const Color(0xFFB94040);
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool amber, green;
  final Color? color;
  const _Tag(this.label, {this.amber = false, this.green = false, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (amber ? AppColors.suspendedText
        : green ? AppColors.activeText
        : AppColors.textSecondary);
    final bg = amber ? AppColors.suspendedBg
        : green ? AppColors.activeBg
        : AppColors.deletedBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(
          fontFamily: 'DMSans', fontSize: 10,
          fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11,
        color: color ?? AppColors.textSecondary),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(
        fontFamily: 'DMSans', fontSize: 11,
        color: color ?? AppColors.textSecondary)),
  ]);
}

class _StatusCfg {
  final IconData icon;
  final Color bg, fg;
  final String label;
  const _StatusCfg(this.icon, this.bg, this.fg, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
//  INVOICES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _InvoicesTab extends StatelessWidget {
  final bool loading;
  final List<OpsInvoice> invoices;
  final String filter;
  final TextEditingController search;
  final ValueChanged<String> onFilter;
  final VoidCallback onRefresh;
  final void Function(OpsInvoice) onDelete;
  final void Function(OpsInvoice) onTap;

  const _InvoicesTab({
    required this.loading, required this.invoices, required this.filter,
    required this.search, required this.onFilter, required this.onRefresh,
    required this.onDelete, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    // Search
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: search,
          style: AppTextStyles.rowValue.copyWith(fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: 'Search vendor, currency, type…',
            hintStyle: AppTextStyles.emailSubtle,
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 19),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: search,
              builder: (_, v, __) => v.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondary, size: 17),
                  onPressed: search.clear),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ),
    _FilterRow(
      items: const [
        ('', 'All'), ('COMPLETED', 'Completed'),
        ('PROCESSING', 'Processing'), ('FAILED', 'Failed'),
      ],
      selected: filter,
      onSelected: onFilter,
    ),
    Expanded(
      child: loading
          ? const Center(child: CircularProgressIndicator(
          color: AppColors.accentGreen))
          : invoices.isEmpty
          ? const _EmptyState(icon: Icons.receipt_long_outlined,
          label: 'No invoices')
          : RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.accentGreen,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: invoices.length,
          itemBuilder: (_, i) => _InvoiceCard(
            invoice:  invoices[i],
            onTap:    () => onTap(invoices[i]),
            onDelete: () => onDelete(invoices[i]),
          ),
        ),
      ),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  INVOICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final OpsInvoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _InvoiceCard({required this.invoice, required this.onTap,
    required this.onDelete});

  Color get _statusColor => invoice.status == 'COMPLETED'
      ? AppColors.activeText
      : invoice.status == 'PROCESSING' ? AppColors.suspendedText
      : const Color(0xFFB94040);

  Color get _statusBg => invoice.status == 'COMPLETED'
      ? AppColors.activeBg
      : invoice.status == 'PROCESSING' ? AppColors.suspendedBg
      : const Color(0xFFFBDEDA);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Thumbnail / icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: invoice.isImage
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  invoice.fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.receipt_long_rounded,
                      size: 22, color: AppColors.textSecondary),
                ),
              )
                  : const Icon(Icons.receipt_long_rounded,
                  size: 22, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(invoice.vendorName ?? 'Unknown vendor',
                  style: AppTextStyles.nameBold.copyWith(fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Wrap(spacing: 4, runSpacing: 2, children: [
                if (invoice.invoiceDate != null)
                  Text(_fmtDate(invoice.invoiceDate),
                      style: AppTextStyles.emailSubtle.copyWith(fontSize: 11)),
                _Tag(invoice.type == 'BUSINESS' ? 'Business' : 'Personal',
                    green: invoice.type == 'BUSINESS'),
                if (invoice.paymentMethod != null)
                  _Tag(invoice.paymentMethod!),
              ]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (invoice.totalAmount != null)
                Text('${invoice.currency} ${invoice.totalAmount!.toStringAsFixed(2)}',
                    style: AppTextStyles.nameBold.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  invoice.status == 'COMPLETED' ? 'Done' : invoice.status,
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 10.5,
                      fontWeight: FontWeight.w700, color: _statusColor),
                ),
              ),
            ]),
          ]),
        ),
        // Bottom: confidence + items count + delete
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
          ),
          child: Row(children: [
            if (invoice.confidenceScore != null) ...[
              _ConfidenceDot(invoice.confidenceScore!),
              const SizedBox(width: 4),
              Text('${(invoice.confidenceScore! * 100).round()}%',
                  style: AppTextStyles.footerNote.copyWith(fontSize: 11)),
              const SizedBox(width: 10),
            ],
            Text('${invoice.lineItems.length} item${invoice.lineItems.length == 1 ? '' : 's'}',
                style: AppTextStyles.footerNote.copyWith(fontSize: 11)),
            if (invoice.fileSizeLabel.isNotEmpty) ...[
              const Text(' · ', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
              Text(invoice.fileSizeLabel,
                  style: AppTextStyles.footerNote.copyWith(fontSize: 11)),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFFBDEDA),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 12, color: Color(0xFFB94040)),
                  SizedBox(width: 4),
                  Text('Delete', style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB94040))),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete invoice?', style: AppTextStyles.cardTitle),
        content: Text(
          'This will permanently remove the invoice for '
              '"${invoice.vendorName ?? 'this vendor'}".',
          style: AppTextStyles.rowLabel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.of(dlg).pop(); onDelete(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Delete', style: TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final double score;
  const _ConfidenceDot(this.score);

  Color get _color {
    if (score >= 0.9) return AppColors.activeText;
    if (score >= 0.7) return AppColors.suspendedText;
    return const Color(0xFFB94040);
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILTER ROW (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterRow({required this.items, required this.selected,
    required this.onSelected});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelected(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: item.$1 == selected
                  ? AppColors.darkGreen : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.$1 == selected
                    ? AppColors.darkGreen : AppColors.divider,
              ),
            ),
            child: Text(item.$2, style: TextStyle(
                fontFamily: 'DMSans', fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: item.$1 == selected
                    ? Colors.white : AppColors.textSecondary)),
          ),
        ),
      )).toList(),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.deletedBg, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.textSecondary, size: 26)),
      const SizedBox(height: 14),
      Text(label, style: AppTextStyles.cardTitle),
      const SizedBox(height: 4),
      const Text('Pull down to refresh', style: AppTextStyles.footerNote),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  OCR JOB DETAIL SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class OcrJobDetailScreen extends StatelessWidget {
  final OcrJob job;
  final OpsInvoice? invoice;
  const OcrJobDetailScreen({super.key, required this.job, this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _DetailHeader(
            title: 'OCR Job',
            subtitle: '${job.engine} · ${job.durationLabel}',
            statusLabel: job.status,
            statusColor: job.isFailed ? const Color(0xFFB94040)
                : job.isDone ? AppColors.activeText
                : AppColors.suspendedText,
            statusBg: job.isFailed ? const Color(0xFFFBDEDA)
                : job.isDone ? AppColors.activeBg
                : AppColors.suspendedBg,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // ── Meta card ───────────────────────────────────────────
                _SectionTitle('JOB INFO'),
                const SizedBox(height: 8),
                _InfoCard(rows: [
                  _IR('Job ID',       job.id, copyable: true),
                  _IR('Status',       job.status),
                  _IR('Engine',       job.engine),
                  _IR('Attempts',     '${job.attemptCount}'),
                  _IR('Duration',     job.durationLabel.isNotEmpty ? job.durationLabel : '—'),
                  _IR('Segments',     '${job.segmentCount}${job.multiSegment ? ' (multi)' : ''}'),
                  if (job.mergeStrategy != null)
                    _IR('Merge',      job.mergeStrategy!),
                  _IR('Created',      _fmtDate(job.createdAt)),
                  if (job.completedAt != null)
                    _IR('Completed',  _fmtDate(job.completedAt)),
                ]),

                if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBDEDA),
                      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFB94040), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(job.errorMessage!,
                          style: const TextStyle(fontFamily: 'DMSans',
                              fontSize: 13, color: Color(0xFFB94040), height: 1.5))),
                    ]),
                  ),
                ],

                // ── OCR insights ────────────────────────────────────────
                if (job.vendorName != null || job.primaryCategory != null ||
                    job.imageQuality != null) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('OCR INSIGHTS'),
                  const SizedBox(height: 8),
                  _InfoCard(rows: [
                    if (job.vendorName != null)
                      _IR('Vendor',       job.vendorName!),
                    if (job.city != null || job.country != null)
                      _IR('Location',     [job.city, job.country]
                          .where((s) => s != null).join(', ')),
                    if (job.documentType != null)
                      _IR('Doc type',     job.documentType!),
                    if (job.primaryCategory != null)
                      _IR('Category',     job.primaryCategory!),
                    if (job.subCategory != null)
                      _IR('Sub-category', job.subCategory!),
                    if (job.categoryConfidence != null)
                      _IR('Cat. confidence',
                          '${(job.categoryConfidence! * 100).round()}%'),
                    if (job.imageQuality != null)
                      _IR('Image quality', job.imageQuality!),
                    if (job.overallConfidence != null)
                      _IR('OCR confidence',
                          '${(job.overallConfidence! * 100).round()}%'),
                    if (job.grandTotal != null)
                      _IR('Grand total',
                          '${job.detectedCurrency ?? ''} ${job.grandTotal!.toStringAsFixed(2)}'),
                  ]),
                ],

                // ── Linked invoice ──────────────────────────────────────
                if (invoice != null) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('LINKED INVOICE'),
                  const SizedBox(height: 8),
                  _LinkedInvoiceCard(
                    invoice:  invoice!,
                    onViewImage: () => _openImage(context, invoice!.fullImageUrl),
                    onOpenDetail: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            OpsInvoiceDetailScreen(
                                invoice: invoice!, onDelete: () {}))),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => _ImageViewerScreen(url: url)));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  INVOICE DETAIL SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class OpsInvoiceDetailScreen extends StatelessWidget {
  final OpsInvoice invoice;
  final OcrJob? job;
  final VoidCallback onDelete;

  const OpsInvoiceDetailScreen({
    super.key,
    required this.invoice,
    this.job,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _DetailHeader(
            title: invoice.vendorName ?? 'Invoice',
            subtitle: '${invoice.currency} · ${invoice.type}',
            statusLabel: invoice.status == 'COMPLETED' ? 'Done' : invoice.status,
            statusColor: invoice.status == 'COMPLETED'
                ? AppColors.activeText : AppColors.suspendedText,
            statusBg: invoice.status == 'COMPLETED'
                ? AppColors.activeBg : AppColors.suspendedBg,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // ── Image viewer ────────────────────────────────────────
                if (invoice.isImage) ...[
                  _ReceiptImageCard(
                    imageUrl: invoice.fullImageUrl,
                    fileName: invoice.fileName,
                    onExpand: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) =>
                            _ImageViewerScreen(url: invoice.fullImageUrl))),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Core details ─────────────────────────────────────────
                const _SectionTitle('INVOICE DETAILS'),
                const SizedBox(height: 8),
                _InfoCard(rows: [
                  _IR('Invoice ID',   invoice.id, copyable: true),
                  _IR('Vendor',       invoice.vendorName ?? '—'),
                  _IR('Date',         _fmtDate(invoice.invoiceDate)),
                  _IR('Total',        invoice.totalAmount != null
                      ? '${invoice.currency} ${invoice.totalAmount!.toStringAsFixed(2)}'
                      : '—'),
                  if (invoice.taxAmount != null && invoice.taxAmount! > 0)
                    _IR('Tax',        '${invoice.currency} ${invoice.taxAmount!.toStringAsFixed(2)}'),
                  _IR('Type',         invoice.type),
                  if (invoice.paymentMethod != null)
                    _IR('Payment',    invoice.paymentMethod!),
                  _IR('Status',       invoice.status),
                  if (invoice.confidenceScore != null)
                    _IR('Confidence', '${(invoice.confidenceScore! * 100).round()}%'),
                  _IR('Created',      _fmtDate(invoice.createdAt)),
                  _IR('File',         invoice.fileName),
                  if (invoice.fileSizeLabel.isNotEmpty)
                    _IR('Size',       invoice.fileSizeLabel),
                ]),

                // ── Line items ───────────────────────────────────────────
                if (invoice.lineItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionTitle('LINE ITEMS (${invoice.lineItems.length})'),
                  const SizedBox(height: 8),
                  _LineItemsCard(
                      items: invoice.lineItems,
                      currency: invoice.currency),
                ],

                // ── OCR job info ─────────────────────────────────────────
                if (job != null) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('OCR JOB'),
                  const SizedBox(height: 8),
                  _InfoCard(rows: [
                    _IR('Job ID',     job!.id, copyable: true),
                    _IR('Engine',     job!.engine),
                    _IR('Status',     job!.status),
                    _IR('Duration',   job!.durationLabel),
                    if (job!.imageQuality != null)
                      _IR('Image quality', job!.imageQuality!),
                    if (job!.overallConfidence != null)
                      _IR('Confidence', '${(job!.overallConfidence! * 100).round()}%'),
                  ]),
                ],

                const SizedBox(height: 24),

                // ── Delete ───────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.dangerRed, size: 17),
                  label: const Text('Delete invoice',
                      style: TextStyle(fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600, fontSize: 14,
                          color: AppColors.dangerRed)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.dangerBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete invoice?', style: AppTextStyles.cardTitle),
        content: Text(
            'This will permanently remove the invoice for '
                '"${invoice.vendorName ?? 'this vendor'}".',
            style: AppTextStyles.rowLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: Text('Cancel', style: AppTextStyles.actionButton
                .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dlg).pop();
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Delete', style: TextStyle(
                fontFamily: 'DMSans', fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECEIPT IMAGE CARD  (thumbnail + expand button)
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptImageCard extends StatelessWidget {
  final String imageUrl, fileName;
  final VoidCallback onExpand;
  const _ReceiptImageCard({required this.imageUrl, required this.fileName,
    required this.onExpand});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onExpand,
    child: Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(
          child: Image.network(
            imageUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.image_not_supported_outlined,
                  size: 40, color: AppColors.textSecondary),
            ),
            loadingBuilder: (_, child, prog) => prog == null ? child : const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen,
                  strokeWidth: 2),
            ),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Bottom labels
        Positioned(left: 12, right: 12, bottom: 10, child: Row(children: [
          Expanded(child: Text(fileName,
              style: const TextStyle(fontFamily: 'DMSans', fontSize: 11,
                  color: Colors.white70),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.fullscreen_rounded, size: 13, color: Colors.white),
              SizedBox(width: 4),
              Text('View full', style: TextStyle(fontFamily: 'DMSans',
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ])),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  FULL-SCREEN IMAGE VIEWER  (pinch-zoom via InteractiveViewer)
// ─────────────────────────────────────────────────────────────────────────────

class _ImageViewerScreen extends StatelessWidget {
  final String url;
  const _ImageViewerScreen({required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(children: [
      Center(
        child: InteractiveViewer(
          minScale: 0.5, maxScale: 8.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.image_not_supported_outlined,
                  size: 60, color: Colors.white54),
            ),
            loadingBuilder: (_, child, prog) => prog == null
                ? child
                : const Center(child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)),
          ),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ),
      Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 0, right: 0,
        child: const Center(
          child: Text('Pinch to zoom · swipe to dismiss',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                  color: Colors.white54)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  LINKED INVOICE CARD  (in job detail)
// ─────────────────────────────────────────────────────────────────────────────

class _LinkedInvoiceCard extends StatelessWidget {
  final OpsInvoice invoice;
  final VoidCallback onViewImage;
  final VoidCallback onOpenDetail;
  const _LinkedInvoiceCard({required this.invoice, required this.onViewImage,
    required this.onOpenDetail});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: [
      if (invoice.isImage) ...[
        GestureDetector(
          onTap: onViewImage,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppMetrics.cardRadius)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(
                invoice.fullImageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.deletedBg,
                  child: const Center(child: Icon(Icons.receipt_long_rounded,
                      size: 36, color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(invoice.vendorName ?? 'Unknown vendor',
                style: AppTextStyles.nameBold.copyWith(fontSize: 14))),
            if (invoice.totalAmount != null)
              Text('${invoice.currency} ${invoice.totalAmount!.toStringAsFixed(2)}',
                  style: AppTextStyles.nameBold.copyWith(
                      fontSize: 14, color: AppColors.accentGreen)),
          ]),
          const SizedBox(height: 4),
          Text('${invoice.lineItems.length} line items · ${_fmtDate(invoice.invoiceDate)}',
              style: AppTextStyles.emailSubtle.copyWith(fontSize: 12)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onOpenDetail,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('View full invoice', style: TextStyle(
                    fontFamily: 'DMSans', fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  LINE ITEMS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LineItemsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String currency;
  const _LineItemsCard({required this.items, required this.currency});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          const Expanded(child: Text('Item',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary))),
          const Text('Qty', style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
              fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          const SizedBox(width: 80, child: Text('Amount',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary))),
        ]),
      ),
      const Divider(height: 1, color: AppColors.divider),
      ...items.asMap().entries.map((e) {
        final item = e.value;
        final desc = item['description']?.toString()
            ?? item['item_name']?.toString() ?? '—';
        final qty  = item['quantity']?.toString() ?? '1';
        final amt  = (item['amount'] as num?)?.toDouble();
        final amtStr = amt != null
            ? '$currency ${amt.toStringAsFixed(2)}' : '—';
        final isLast = e.key == items.length - 1;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(desc, style: const TextStyle(fontFamily: 'DMSans',
                    fontSize: 13, color: AppColors.textPrimary)),
                if (item['productType'] != null) ...[
                  const SizedBox(height: 2),
                  Text(item['productType'].toString(),
                      style: const TextStyle(fontFamily: 'DMSans', fontSize: 10,
                          color: AppColors.textSecondary)),
                ],
              ])),
              const SizedBox(width: 8),
              Text(qty, style: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              SizedBox(width: 80, child: Text(amtStr,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'DMSans',
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
            ]),
          ),
          if (!isLast)
            const Divider(height: 1, indent: 16, endIndent: 16,
                color: AppColors.divider),
        ]);
      }),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED DETAIL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final String title, subtitle, statusLabel;
  final Color statusColor, statusBg;
  const _DetailHeader({required this.title, required this.subtitle,
    required this.statusLabel, required this.statusColor,
    required this.statusBg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(4, 8, 16, 28),
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left_rounded,
            color: Colors.white, size: 26),
        padding: EdgeInsets.zero,
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.headerTitle.copyWith(fontSize: 19),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(subtitle, style: AppTextStyles.headerSubtitle),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
            color: statusBg.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20)),
        child: Text(statusLabel, style: TextStyle(
            fontFamily: 'DMSans', fontSize: 12,
            fontWeight: FontWeight.w700, color: statusColor)),
      ),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);
  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.sectionLabel);
}

class _IR {
  final String label, value;
  final bool copyable;
  const _IR(this.label, this.value, {this.copyable = false});
}

class _InfoCard extends StatelessWidget {
  final List<_IR> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(
      children: rows.asMap().entries.map((e) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.value.label, style: AppTextStyles.rowLabel),
            const SizedBox(width: 16),
            Flexible(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(e.value.value.isEmpty ? '—' : e.value.value,
                  style: AppTextStyles.rowValue.copyWith(fontSize: 14),
                  textAlign: TextAlign.right,
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (e.value.copyable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: e.value.value));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${e.value.label} copied'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: const Icon(Icons.copy_rounded, size: 13,
                      color: AppColors.textSecondary),
                ),
              ],
            ])),
          ]),
        ),
        if (e.key < rows.length - 1)
          const Divider(height: 1, color: AppColors.divider),
      ])).toList(),
    ),
  );
}