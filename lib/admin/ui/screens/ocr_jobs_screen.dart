import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/admin_bottom_nav.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum OcrJobStatus { pending, processing, failed, done }

class OcrJob {
  final String id;
  final String fileName;
  final String engine;
  final OcrJobStatus status;
  final String? attempt;
  final String? segments;
  final String? queuedAgo;
  final String? duration;
  final String? errorMessage;

  const OcrJob({
    required this.id,
    required this.fileName,
    required this.engine,
    required this.status,
    this.attempt,
    this.segments,
    this.queuedAgo,
    this.duration,
    this.errorMessage,
  });

  String get subtitle {
    final parts = <String>[engine];
    if (attempt != null) parts.add('attempt $attempt');
    if (segments != null) parts.add('$segments segments');
    if (queuedAgo != null) parts.add('queued $queuedAgo');
    if (duration != null) parts.add(duration!);
    return parts.join(' · ');
  }
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockJobs = [
  const OcrJob(
    id: '1', fileName: 'Canada Computers.jpeg', engine: 'GPT4',
    status: OcrJobStatus.failed, attempt: '2', segments: '3',
    errorMessage: 'Timeout after 30s — model latency',
  ),
  const OcrJob(
    id: '2', fileName: 'Receipt_0912.pdf', engine: 'GPT4',
    status: OcrJobStatus.processing, queuedAgo: '12s ago',
  ),
  const OcrJob(
    id: '3', fileName: 'grocery_aug.jpeg', engine: 'Tesseract',
    status: OcrJobStatus.pending, queuedAgo: 'waiting',
  ),
  const OcrJob(
    id: '4', fileName: 'invoice_778.pdf', engine: 'GPT4',
    status: OcrJobStatus.done, duration: '4.2s', segments: 'merged 2 segs',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OcrJobsScreen extends StatefulWidget {
  const OcrJobsScreen({super.key});

  @override
  State<OcrJobsScreen> createState() => _OcrJobsScreenState();
}

class _OcrJobsScreenState extends State<OcrJobsScreen> {
  OcrJobStatus? _filter; // null = All

  List<OcrJob> get _filtered => _filter == null
      ? _mockJobs
      : _mockJobs.where((j) => j.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final pending   = _mockJobs.where((j) => j.status == OcrJobStatus.pending).length;
    final failed    = _mockJobs.where((j) => j.status == OcrJobStatus.failed).length;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _OcrHeader(pending: pending, failed: failed),
          _FilterChips(
            selected: _filter,
            onSelected: (s) => setState(() => _filter = s),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppMetrics.pagePadding, 8,
                        AppMetrics.pagePadding, 100),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _JobCard(
                      job: _filtered[i],
                      onRetry: _filtered[i].status == OcrJobStatus.failed
                          ? () => _retry(_filtered[i])
                          : null,
                    ),
                  ),
          ),
        ]),
      ),
    ),
    );

  }

  void _retry(OcrJob job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying ${job.fileName}…'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.darkGreen,
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _OcrHeader extends StatelessWidget {
  final int pending, failed;
  const _OcrHeader({required this.pending, required this.failed});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppMetrics.headerRadius)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left,
            color: AppColors.textOnDark, size: 26),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OCR jobs', style: AppTextStyles.headerTitle),
          const SizedBox(height: 4),
          Row(children: [
            _HeaderPill('$pending pending', AppColors.suspendedBg,
                AppColors.suspendedText),
            const SizedBox(width: 8),
            _HeaderPill('$failed failed', const Color(0xFFFBDEDA),
                const Color(0xFFB94040)),
            const SizedBox(width: 8),
            _HeaderPill('queue healthy', AppColors.activeBg,
                AppColors.activeText),
          ]),
        ],
      )),
      _CircleAction(
        icon: Icons.autorenew_rounded,
        onTap: () {},
      ),
    ]),
  );
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _HeaderPill(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: bg.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
  );
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final OcrJobStatus? selected;
  final ValueChanged<OcrJobStatus?> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _Chip(label: 'All', active: selected == null,
            onTap: () => onSelected(null)),
        const SizedBox(width: 8),
        _Chip(label: 'Pending', active: selected == OcrJobStatus.pending,
            onTap: () => onSelected(OcrJobStatus.pending)),
        const SizedBox(width: 8),
        _Chip(label: 'Processing', active: selected == OcrJobStatus.processing,
            onTap: () => onSelected(OcrJobStatus.processing)),
        const SizedBox(width: 8),
        _Chip(label: 'Failed', active: selected == OcrJobStatus.failed,
            onTap: () => onSelected(OcrJobStatus.failed)),
        const SizedBox(width: 8),
        _Chip(label: 'Done', active: selected == OcrJobStatus.done,
            onTap: () => onSelected(OcrJobStatus.done)),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.darkGreen : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: active ? AppColors.darkGreen : AppColors.divider),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

// ── Job card ──────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final OcrJob job;
  final VoidCallback? onRetry;
  const _JobCard({required this.job, this.onRetry});

  _StatusConfig get _cfg {
    switch (job.status) {
      case OcrJobStatus.failed:
        return _StatusConfig(Icons.warning_amber_rounded,
            const Color(0xFFFBDEDA), const Color(0xFFB94040), 'Failed');
      case OcrJobStatus.processing:
        return _StatusConfig(Icons.access_time_rounded,
            AppColors.suspendedBg, AppColors.suspendedText, 'Processing');
      case OcrJobStatus.pending:
        return _StatusConfig(Icons.access_time_rounded,
            AppColors.activeBg.withOpacity(0.6),
            AppColors.textSecondary, 'Pending');
      case OcrJobStatus.done:
        return _StatusConfig(Icons.check_rounded,
            AppColors.activeBg, AppColors.activeText, 'Done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: cfg.iconBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(cfg.icon, color: cfg.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.fileName,
                    style: AppTextStyles.nameBold.copyWith(fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(job.subtitle,
                    style: AppTextStyles.emailSubtle,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            const SizedBox(width: 8),
            _StatusPill(label: cfg.label, bg: cfg.iconBg, fg: cfg.color),
          ]),
        ),
        if (job.errorMessage != null) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              Expanded(child: Text(job.errorMessage!,
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13, color: const Color(0xFFB94040)))),
              const SizedBox(width: 12),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _StatusConfig {
  final IconData icon;
  final Color iconBg, color;
  final String label;
  const _StatusConfig(this.icon, this.iconBg, this.color, this.label);
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _StatusPill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.task_alt_rounded, size: 52, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text('No jobs here', style: AppTextStyles.statLabel),
    ]),
  );
}

// ── Shared circle action button ───────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}
