import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.metadata,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> j) =>
      NotificationItem(
        id: j['id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        metadata: (j['metadata'] as Map<String, dynamic>?) ?? {},
        readAt:
            j['readAt'] != null ? DateTime.tryParse(j['readAt'] as String) : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  NotificationItem copyWith({DateTime? readAt}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        metadata: metadata,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );
}


// ─────────────────────────────────────────────────────────────────────────────
//  Notification type config — extend as new types arrive
// ─────────────────────────────────────────────────────────────────────────────

class _TypeConfig {
  final IconData icon;
  final Color color;
  final Color surface;

  const _TypeConfig(this.icon, this.color, this.surface);
}

const Map<String, _TypeConfig> _typeMap = {
  'OCR_COMPLETED': _TypeConfig(
    Icons.document_scanner_rounded,
    WerlogColors.teal,
    WerlogColors.tealSurface,
  ),
  'PAYMENT_SUCCESS': _TypeConfig(
    Icons.check_circle_rounded,
    WerlogColors.teal,
    WerlogColors.tealSurface,
  ),
  'PAYMENT_FAILED': _TypeConfig(
    Icons.error_rounded,
    WerlogColors.coral,
    WerlogColors.coralSurface,
  ),
  'WARRANTY_EXPIRING': _TypeConfig(
    Icons.timer_rounded,
    WerlogColors.amber,
    WerlogColors.amberSurface,
  ),
  'NEW_FEATURE': _TypeConfig(
    Icons.new_releases_rounded,
    WerlogColors.purple,
    WerlogColors.purpleSurface,
  ),
};

_TypeConfig _typeConfig(String type) =>
    _typeMap[type] ??
    const _TypeConfig(
      Icons.notifications_rounded,
      WerlogColors.blue,
      WerlogColors.blueSurface,
    );

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationsScreen
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  List<NotificationItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 0;
  int _totalPages = 1;
  final _scrollCtrl = ScrollController();

  // filter: 'all' | 'unread'
  String _filter = 'all';

  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();

    _scrollCtrl.addListener(_onScroll);
      _fetchNotifications(page: 0, refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 120 &&
        !_loadingMore &&
        _page + 1 < _totalPages) {
      _fetchNotifications(page: _page + 1);
    }
  }

  // ── API ────────────────────────────────────────────────────────────────────

  Future<void> _fetchNotifications({
    required int page,
    bool refresh = false,
  }) async {
    // Show skeleton on first load / pull-to-refresh; spinner at bottom for
    // pagination loads.
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final response = await ApiService.get(
        context,
        '${Endpoints.GET_USER_NOTIFICATIONS}?page=$page&size=20',
      );

      debugPrint('\nNOTIFICATIONS => $response');

      final success = response['result'] == '1';

      if (success) {
        // ── parse items ───────────────────────────────────────────────────
        final rawList = (response['data'] as List?) ?? [];
        final newItems = rawList
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();

        // ── parse pagination ──────────────────────────────────────────────
        final pagination =
            (response['pagination'] as Map<String, dynamic>?) ?? {};
        final newPage = (pagination['page'] as num?)?.toInt() ?? page;
        final newTotalPages =
            (pagination['totalPages'] as num?)?.toInt() ?? 1;

        setState(() {
          if (refresh) {
            _items = newItems;
          } else {
            // Avoid duplicates when paginating
            final existingIds = _items.map((n) => n.id).toSet();
            _items = [
              ..._items,
              ...newItems.where((n) => !existingIds.contains(n.id)),
            ];
          }
          _page = newPage;
          _totalPages = newTotalPages;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        // Server returned result != "1"
        setState(() {
          _loading = false;
          _loadingMore = false;
          // Keep _error null so existing items (if any) stay visible;
          // only show it on a fresh load with no data.
          if (_items.isEmpty) _error = response['message']?.toString();
        });

        if (mounted) {
          GeneralFunctions.showError(
            context,
            response['message']?.toString() ?? 'Something went wrong.',
          );
        }
      }
    } catch (e) {
      debugPrint('NOTIFICATIONS ERROR => $e');

      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_items.isEmpty) _error = e.toString();
      });

      if (mounted) {
        GeneralFunctions.showError(
          context,
          'Process interrupted. Please try again!',
        );
      }
    }
  }

  // ── mark read ──────────────────────────────────────────────────────────────

  void _markRead(String id) {
    // TODO: call PATCH /api/notifications/:id/read
    setState(() {
      _items = _items.map((n) {
        if (n.id == id) return n.copyWith(readAt: DateTime.now());
        return n;
      }).toList();
    });
  }

  void _markAllRead() {
    HapticFeedback.lightImpact();
    // TODO: call POST /api/notifications/mark-all-read
    final now = DateTime.now();
    setState(() {
      _items = _items.map((n) => n.copyWith(readAt: now)).toList();
    });
    _showSnack('All notifications marked as read');
  }

  void _dismiss(String id) {
    // TODO: call DELETE /api/notifications/:id
    setState(() => _items.removeWhere((n) => n.id == id));
    _showSnack('Notification removed');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: WerlogTextStyles.bodySmall
                .copyWith(color: WerlogColors.textWhite)),
        backgroundColor: WerlogColors.darkTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── derived ────────────────────────────────────────────────────────────────

  List<NotificationItem> get _filtered =>
      _filter == 'unread' ? _items.where((n) => n.isUnread).toList() : _items;

  int get _unreadCount => _items.where((n) => n.isUnread).length;

  // ── time formatting ────────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    final diff = today.difference(d).inDays;
    if (diff < 7) return 'This Week';
    if (diff < 30) return 'This Month';
    return 'Earlier';
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: Column(
        children: [
          _buildHeader(top),
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(double top) {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        color: WerlogColors.background,
        padding: EdgeInsets.fromLTRB(20, top + 12, 16, 12),
        child: Row(
          children: [
            // back
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: WerlogColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WerlogColors.border, width: 0.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: WerlogColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            // title + unread badge
            Expanded(
              child: Row(
                children: [
                  Text('Notifications', style: WerlogTextStyles.pageTitle),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: WerlogColors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // mark all read
            if (_unreadCount > 0)
              GestureDetector(
                onTap: _markAllRead,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: WerlogColors.tealSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: WerlogColors.teal.withOpacity(0.25), width: 0.5),
                  ),
                  child: Text(
                    'Mark all read',
                    style: WerlogTextStyles.bodySmall.copyWith(
                      color: WerlogColors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── filter bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: WerlogColors.background,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            count: _items.length,
            selected: _filter == 'all',
            onTap: () => setState(() => _filter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Unread',
            count: _unreadCount,
            selected: _filter == 'unread',
            onTap: () => setState(() => _filter = 'unread'),
            accent: true,
          ),
        ],
      ),
    );
  }

  // ── body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildList() {
    // Group by time label
    final groups = <String, List<NotificationItem>>{};
    for (final item in _filtered) {
      final label = _groupLabel(item.createdAt);
      groups.putIfAbsent(label, () => []).add(item);
    }

    // Ordered labels
    const order = ['Today', 'Yesterday', 'This Week', 'This Month', 'Earlier'];
    final orderedKeys = order.where(groups.containsKey).toList();

    return RefreshIndicator(
      color: WerlogColors.teal,
      backgroundColor: WerlogColors.surface,
      onRefresh: () => _fetchNotifications(page: 0, refresh: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: orderedKeys.length +
            (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, sectionIdx) {
          if (sectionIdx == orderedKeys.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(WerlogColors.teal),
                  ),
                ),
              ),
            );
          }

          final key = orderedKeys[sectionIdx];
          final groupItems = groups[key]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text(
                  key.toUpperCase(),
                  style: WerlogTextStyles.labelUppercase.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    color: WerlogColors.textTertiary,
                  ),
                ),
              ),
              ...groupItems.map((item) {
                return _NotificationTile(
                  key: ValueKey(item.id),
                  item: item,
                  relativeTime: _relativeTime(item.createdAt),
                  onTap: () {
                    if (item.isUnread) _markRead(item.id);
                    // TODO: navigate based on item.type / metadata
                  },
                  onDismiss: () => _dismiss(item.id),
                  onMarkRead: item.isUnread ? () => _markRead(item.id) : null,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // ── skeleton ───────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 6,
      itemBuilder: (_, i) => const _SkeletonTile(),
    );
  }

  // ── empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: WerlogColors.tealSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 32, color: WerlogColors.teal),
          ),
          const SizedBox(height: 16),
          Text(
            _filter == 'unread' ? 'All caught up!' : 'No notifications yet',
            style: WerlogTextStyles.sectionTitle,
          ),
          const SizedBox(height: 6),
          Text(
            _filter == 'unread'
                ? 'You have no unread notifications.'
                : "We'll notify you when something happens.",
            style: WerlogTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (_filter == 'unread') ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _filter = 'all'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: WerlogColors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('View all',
                    style: WerlogTextStyles.bodySmall
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── error ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: WerlogColors.coralSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.wifi_off_rounded,
                size: 30, color: WerlogColors.coral),
          ),
          const SizedBox(height: 16),
          Text('Something went wrong', style: WerlogTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text('Pull to refresh or try again.',
              style: WerlogTextStyles.bodySmall),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _fetchNotifications(page: 0, refresh: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: WerlogColors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Retry',
                  style: WerlogTextStyles.bodySmall
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatefulWidget {
  final NotificationItem item;
  final String relativeTime;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback? onMarkRead;

  const _NotificationTile({
    super.key,
    required this.item,
    required this.relativeTime,
    required this.onTap,
    required this.onDismiss,
    this.onMarkRead,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig(widget.item.type);
    final isUnread = widget.item.isUnread;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: ValueKey(widget.item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDismiss(),
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: WerlogColors.coral,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isUnread ? WerlogColors.surface : WerlogColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnread
                      ? WerlogColors.teal.withOpacity(0.2)
                      : WerlogColors.border,
                  width: isUnread ? 1 : 0.5,
                ),
                boxShadow: isUnread
                    ? [
                        BoxShadow(
                          color: WerlogColors.teal.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // icon
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: cfg.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cfg.icon, color: cfg.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  style: WerlogTextStyles.cardTitle.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: WerlogColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.relativeTime,
                                style: WerlogTextStyles.captionSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.item.body,
                            style: WerlogTextStyles.bodySmall.copyWith(
                              color: isUnread
                                  ? WerlogColors.textSecondary
                                  : WerlogColors.textTertiary,
                              height: 1.45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // metadata pill (invoiceId etc.)
                          if (widget.item.metadata['invoiceId'] != null) ...[
                            const SizedBox(height: 8),
                            _MetadataPill(
                              icon: Icons.receipt_long_rounded,
                              label: 'Invoice',
                              value: '#${(widget.item.metadata['invoiceId'] as String).substring(0, 8)}',
                              color: cfg.color,
                              surface: cfg.surface,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // unread dot
                    if (isUnread)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: WerlogColors.teal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Metadata pill
// ─────────────────────────────────────────────────────────────────────────────

class _MetadataPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color surface;

  const _MetadataPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$label · $value',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accent ? WerlogColors.teal : WerlogColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (accent ? WerlogColors.teal : WerlogColors.darkTeal)
              : WerlogColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : WerlogColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : WerlogColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : (accent
                          ? WerlogColors.tealSurface
                          : WerlogColors.surfaceAlt),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : (accent ? WerlogColors.teal : WerlogColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton tile
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile();

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer =
            Color.lerp(WerlogColors.surfaceAlt, WerlogColors.border, _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WerlogColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WerlogColors.border, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 110,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
