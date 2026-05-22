import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';
import 'expense_new/fresh/warranty_detail_screen.dart';

// ─────────────────────────────────────────
//  DATA MODELS — replace with API response
// ─────────────────────────────────────────
class InvoiceLineItemData {
  final String description;
  final int    quantity;
  final double unitPrice;
  final double amount;

  const InvoiceLineItemData({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLineItemData.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItemData(
        description: json['description']?.toString() ?? '',
        quantity:    (json['quantity']  as num?)?.toInt()    ?? 1,
        unitPrice:   (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        amount:      (json['amount']    as num?)?.toDouble() ?? 0.0,
      );
}

class WarrantyItem {
  final String id;
  final String name;
  final String serial;
  final String purchaseDate;
  final String status; // 'active' | 'expiring_soon' | 'expired' | 'claimed'
  final String expiresOn;
  final String timeLeft;
  final String? imageAsset; // local asset path — null uses icon placeholder
  final String price;
  final String invoiceNo;
  final String warrantyType;
  final String provider;
  final String duration;
  final String claimSupport;
  final String website;// NEW
  final List<String> imageUrls;
  final List<InvoiceLineItemData> items;

  const WarrantyItem({
    required this.id,
    required this.name,
    required this.serial,
    required this.purchaseDate,
    required this.status,
    required this.expiresOn,
    required this.timeLeft,
    this.imageAsset,
    required this.price,
    required this.invoiceNo,
    required this.warrantyType,
    required this.provider,
    required this.duration,
    required this.claimSupport,
    required this.website,
    // NEW
    this.imageUrls = const [],
    this.items = const [],
  });
}

// Demo data per category
class CategoryData {
  static List<WarrantyItem> electronics = [
    WarrantyItem(
      id: 'w001',
      name: 'MacBook Air M2',
      serial: 'C02X1234Y6L5',
      purchaseDate: '15 Mar 2024',
      status: 'active',
      expiresOn: '15 Mar 2026',
      timeLeft: '1y 7m left',
      price: '₹1,09,900',
      invoiceNo: 'INV-2024-1548',
      warrantyType: 'Manufacturer Warranty',
      provider: 'Apple India',
      duration: '2 Years',
      claimSupport: '1800-123-4567',
      website: 'www.apple.com/support',
    ),
    WarrantyItem(
      id: 'w002',
      name: 'Sony 55" 4K TV',
      serial: '8K1X88M2P3',
      purchaseDate: '10 Jan 2024',
      status: 'expiring_soon',
      expiresOn: '10 Jul 2024',
      timeLeft: '2m left',
      price: '₹89,990',
      invoiceNo: 'INV-2024-0042',
      warrantyType: 'Manufacturer Warranty',
      provider: 'Sony India',
      duration: '1 Year',
      claimSupport: '1800-103-7799',
      website: 'www.sony.co.in/support',
    ),
    WarrantyItem(
      id: 'w003',
      name: 'Bose QuietComfort 45',
      serial: '074682991',
      purchaseDate: '05 May 2023',
      status: 'active',
      expiresOn: '05 May 2025',
      timeLeft: '7m left',
      price: '₹32,000',
      invoiceNo: 'INV-2023-3210',
      warrantyType: 'Manufacturer Warranty',
      provider: 'Bose India',
      duration: '2 Years',
      claimSupport: '1800-123-2672',
      website: 'www.bose.com/support',
    ),
    WarrantyItem(
      id: 'w004',
      name: 'Canon EOS R50',
      serial: 'R50A123477',
      purchaseDate: '12 Feb 2023',
      status: 'expired',
      expiresOn: '12 Feb 2024',
      timeLeft: 'Expired',
      price: '₹67,495',
      invoiceNo: 'INV-2023-0879',
      warrantyType: 'Manufacturer Warranty',
      provider: 'Canon India',
      duration: '1 Year',
      claimSupport: '1800-180-3366',
      website: 'www.canon.co.in',
    ),
    WarrantyItem(
      id: 'w005',
      name: 'WD My Passport 2TB',
      serial: 'WX72A1K9D3',
      purchaseDate: '01 Dec 2023',
      status: 'active',
      expiresOn: '01 Dec 2025',
      timeLeft: '10m left',
      price: '₹6,299',
      invoiceNo: 'INV-2023-7821',
      warrantyType: 'Manufacturer Warranty',
      provider: 'Western Digital',
      duration: '2 Years',
      claimSupport: '1800-419-5034',
      website: 'www.westerndigital.com/support',
    ),
  ];

  static List<WarrantyItem> forCategory(String categoryName) {
    // In production, filter from API by category
    return electronics;
  }

  static Map<String, int> stats(String categoryName) {
    final items = forCategory(categoryName);
    return {
      'total': items.length,
      'active': items.where((i) => i.status == 'active').length,
      'expiring': items.where((i) => i.status == 'expiring_soon').length,
      'expired': items.where((i) => i.status == 'expired').length,
    };
  }
}

class CategoryOverviewScreen extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color iconColor;
  final String catId;

  const CategoryOverviewScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.iconColor,
    required this.catId,
  });

  @override
  State<CategoryOverviewScreen> createState() => _CategoryOverviewScreenState();
}

class _CategoryOverviewScreenState extends State<CategoryOverviewScreen> {
  String _sortBy = 'Purchase Date';
  String _searchQuery = '';

  List<WarrantyItem> get _filteredItems {
    var items = CategoryData.forCategory(widget.categoryName);
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCategoryDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = CategoryData.stats(widget.categoryName);

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(stats),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildSearchBar(),
                          const SizedBox(height: 10),
                          _buildSortRow(),
                          const SizedBox(height: 12),
                          ..._filteredItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _warrantyListItem(context, item),
                              )),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: WerlogColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Warranty',
            style: WerlogTextStyles.button.copyWith(fontSize: 13)),
      ),*/
    );
  }

  // ── App bar ───────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: WerlogColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Icon(widget.categoryIcon, color: widget.iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.categoryName,
              style: WerlogTextStyles.pageTitle.copyWith(fontSize: 18),
            ),
          ),
          /*IconButton(
            icon: const Icon(Icons.more_vert,
                color: WerlogColors.textPrimary, size: 22),
            onPressed: () {},
          ),*/
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────
  Widget _buildStatsRow(Map<String, int> stats) {
    return Container(
      decoration: BoxDecoration(
        gradient: WerlogGradients.pageHeader(),
        border: const Border(
            bottom: BorderSide(color: WerlogColors.border, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _statBox('Total', '${stats['total']}', WerlogColors.textPrimary,
                WerlogColors.surfaceAlt),
            const SizedBox(width: 10),
            _statBox('Active', '${stats['active']}', WerlogColors.teal,
                WerlogColors.tealSurface),
            const SizedBox(width: 10),
            _statBoxWithSub('Expiring Soon', '${stats['expiring']}',
                'Within 90 days', WerlogColors.amber, WerlogColors.amberSurface),
            const SizedBox(width: 10),
            _statBox('Expired', '${stats['expired']}', WerlogColors.coral,
                WerlogColors.coralSurface),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        children: [
          Text(label,
              style: WerlogTextStyles.caption.copyWith(color: color, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: WerlogTextStyles.sectionTitle.copyWith(
                  color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statBoxWithSub(
      String label, String value, String sub, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: color, size: 12),
              const SizedBox(width: 4),
              Text(label,
                  style: WerlogTextStyles.caption
                      .copyWith(color: color, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: WerlogTextStyles.sectionTitle
                  .copyWith(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(sub,
              style: WerlogTextStyles.caption
                  .copyWith(color: color, fontSize: 8)),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: WerlogColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: WerlogColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search,
                    color: WerlogColors.textTertiary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText:
                          'Search in ${widget.categoryName}...',
                      hintStyle: WerlogTextStyles.caption,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: WerlogTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: WerlogColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: WerlogColors.border, width: 0.8),
          ),
          child: const Icon(Icons.filter_list,
              color: WerlogColors.teal, size: 20),
        ),
      ],
    );
  }

  // ── Sort row ──────────────────────────────
  Widget _buildSortRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _sortBy =
                  _sortBy == 'Purchase Date' ? 'Expiry Date' : 'Purchase Date';
            });
          },
          child: Row(
            children: [
              Text('Sort by: $_sortBy',
                  style:
                      WerlogTextStyles.caption.copyWith(fontSize: 11)),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down,
                  color: WerlogColors.textTertiary, size: 16),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.view_list,
            color: WerlogColors.teal, size: 20),
      ],
    );
  }

  // ── Warranty list item ────────────────────
  Widget _warrantyListItem(BuildContext context, WarrantyItem item) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WarrantyDetailScreen(
              item: item,
              imageUrls: item.imageUrls,
            ),
          ),
        );

        if (result == true) {
          getCategoryDetails(); // refresh your API / list
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: WerlogColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.categoryIcon,
                  color: widget.iconColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: WerlogTextStyles.txTitle
                          .copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Serial: ${item.serial}',
                      style: WerlogTextStyles.caption),
                  Text('Purchased: ${item.purchaseDate}',
                      style: WerlogTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(item.status),
                const SizedBox(height: 6),
                Text(
                  item.status == 'expired' ? 'Expired on' : 'Expires on',
                  style: WerlogTextStyles.caption.copyWith(fontSize: 9),
                ),
                Text(item.expiresOn,
                    style: WerlogTextStyles.txTitle.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  item.timeLeft,
                  style: WerlogTextStyles.caption.copyWith(
                    color: _timeLeftColor(item.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final configs = {
      'active': {
        'label': 'Active',
        'bg': WerlogColors.tealSurface,
        'text': WerlogColors.teal,
      },
      'expiring_soon': {
        'label': 'Expiring Soon',
        'bg': WerlogColors.amberSurface,
        'text': WerlogColors.amber,
      },
      'expired': {
        'label': 'Expired',
        'bg': WerlogColors.coralSurface,
        'text': WerlogColors.coral,
      },
      'claimed': {
        'label': 'Claimed',
        'bg': WerlogColors.surfaceAlt,
        'text': WerlogColors.textSecondary,
      },
    };
    final c = configs[status] ?? configs['active']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c['bg'] as Color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        c['label'] as String,
        style: WerlogTextStyles.badgeText.copyWith(
          color: c['text'] as Color,
          fontSize: 9,
        ),
      ),
    );
  }

  Color _timeLeftColor(String status) {
    switch (status) {
      case 'expiring_soon':
        return WerlogColors.amber;
      case 'expired':
        return WerlogColors.coral;
      default:
        return WerlogColors.teal;
    }
  }

  Future<void> getCategoryDetails() async {
    try {
      final response = await ApiService.get(
        context,
        '${Endpoints.WARRANTY_CATEGORY_LIST}${widget.catId}',
      );

      print('\nSUCCESS => $response');

      final result = response['result']=="1" ? true : false;
      if (result) {

        final data = response['data'] ?? {};
        final invoicesList = data['invoiceLists'] ?? [];

        setState(() {

          // =========================================================
          // MAP API LIST -> WARRANTY ITEMS
          // =========================================================

          CategoryData.electronics.clear();

          for (final item in invoicesList) {

            final items = item['items'] ?? [];

            // Take first item if exists
            final firstItem = items.isNotEmpty ? items[0] : {};

            final expiryDateRaw = item['expiryDate'] ?? '';
            final purchaseDateRaw = item['invoiceDate'] ?? '';

            DateTime? expiryDate;
            DateTime? purchaseDate;

            try {
              expiryDate = DateTime.parse(expiryDateRaw);
            } catch (_) {}

            try {
              purchaseDate = DateTime.parse(purchaseDateRaw);
            } catch (_) {}

            // =====================================================
            // STATUS
            // =====================================================

            String status = 'active';

            final apiStatus =
            (item['status'] ?? '').toString().toUpperCase();

            if (apiStatus == 'EXPIRED') {
              status = 'expired';
            } else if (apiStatus == 'CLAIMED') {
              status = 'claimed';
            } else if (expiryDate != null) {

              final remaining =
                  expiryDate.difference(DateTime.now()).inDays;

              if (remaining <= 30 && remaining >= 0) {
                status = 'expiring_soon';
              } else if (remaining < 0) {
                status = 'expired';
              }
            }

            // =====================================================
            // TIME LEFT
            // =====================================================

            String timeLeft = 'N/A';

            if (expiryDate != null) {

              final diff =
                  expiryDate.difference(DateTime.now()).inDays;

              if (diff < 0) {
                timeLeft = 'Expired';
              } else if (diff < 30) {
                timeLeft = '${diff}d left';
              } else if (diff < 365) {
                timeLeft = '${(diff / 30).floor()}m left';
              } else {
                timeLeft = '${(diff / 365).floor()}y left';
              }
            }

            // =====================================================
            // ADD ITEM
            // =====================================================

            CategoryData.electronics.add(
              WarrantyItem(
                id: item['id']?.toString() ??
                    DateTime.now().millisecondsSinceEpoch.toString(),

                imageUrls: List<String>.from(
                  item['imageUrls'] ?? [],
                ),

                // items: items['items'],
                items: (item['items'] as List<dynamic>? ?? [])
                    .map(
                      (e) => InvoiceLineItemData(
                    description: e['description']?.toString() ?? '',
                    quantity: e['quantity'] ?? 0,
                    unitPrice: (e['unitPrice'] ?? 0).toDouble(),
                    amount: (e['amount'] ?? 0).toDouble(),
                  ),
                )
                    .toList(),

                name: firstItem['description']?.toString() ??
                    item['name']?.toString() ??
                    'Unknown Product',

                serial: item['serialno']?.toString() ?? '-',

                purchaseDate: purchaseDate != null
                    ? '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}'
                    : '-',

                status: status,

                expiresOn: expiryDate != null
                    ? '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}'
                    : '-',

                timeLeft: timeLeft,

                price:
                '${firstItem['amount'] ?? firstItem['unitPrice'] ?? 0}',

                invoiceNo:
                item['serialno']?.toString() ?? '-',

                warrantyType: 'Manufacturer Warranty',

                provider:
                item['name']?.toString() ?? '-',

                duration: expiryDate != null &&
                    purchaseDate != null
                    ? '${expiryDate.difference(purchaseDate).inDays ~/ 365} Years'
                    : '-',

                claimSupport: 'N/A',

                website: '',
              ),
            );
          }
        });
      }else{
        GeneralFunctions.showError(
            context,
            response['message'].toString()
        );
      }

    } catch (e) {
      print('ERROR => $e');
      GeneralFunctions.showError(
          context,
          "Process interrupted. Please try again!"
      );
    }
  }
}
