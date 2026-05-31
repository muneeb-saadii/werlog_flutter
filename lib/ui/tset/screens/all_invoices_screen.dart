import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';
import 'category_overview_screen.dart';
import 'expense_new/fresh/warranty_detail_screen.dart';

// ─────────────────────────────────────────
//  DATA MODELS — replace with API response
// ─────────────────────────────────────────

// Demo data per category
class CategoryData {
  static List<WarrantyItem> electronics = [];

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

  static List<IconData> categoryIcons = [
    Icons.monitor,
    Icons.kitchen,
    Icons.smartphone,
    Icons.chair,
    Icons.directions_car,
    Icons.pedal_bike,
    Icons.soup_kitchen,
    Icons.handyman,
  ];
  static const List<int> catColors = [
    0xFF1D9E75, // Electronics
    0xFF0F2A2E, // Home Appliances
    0xFF7B5EA7, // Mobile & Tablets
    0xFFBA7517, // Furniture
    0xFF1D9E75, // Vehicles
    0xFF0F2A2E, // Bikes
    0xFFD85A30, // Kitchen Appliances
    0xFF5DCAA5, // Tools & Equipment
  ];
}


class AllInvoicesScreen extends StatefulWidget {

  const AllInvoicesScreen({
    super.key,
  });

  @override
  State<AllInvoicesScreen> createState() => _AllInvoicesScreenState();
}

class _AllInvoicesScreenState extends State<AllInvoicesScreen> {
  String _sortBy = 'Purchase Date';
  String _searchQuery = '';
  Map<String, int> stats = CategoryData.stats("");

  List<WarrantyItem> allItems = [];
  String selectedStatus = "";
  final List<String> statusOptions = [
    "",
    "ACTIVE",
    "EXPIRED",
    "COMING_SOON",
  ];

  List<WarrantyItem> get _filteredItems {
    // var items = CategoryData.forCategory(widget.categoryName);
    var items = allItems;
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
      getWarrantyInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    if(selectedStatus.isEmpty)
      stats = CategoryData.stats("");

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
                          // const SizedBox(height: 10),
                          // _buildSortRow(),
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
          // Icon(widget.categoryIcon, color: widget.iconColor, size: 22),
          // const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Warranty Invoices"/*widget.categoryName*/,
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Filter By Status",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                ...statusOptions.map((status) {

                  final selected =
                      selectedStatus == status;

                  return GestureDetector(

                    onTap: () async {

                      Navigator.pop(context);

                      setState(() {
                        selectedStatus = status;
                      });

                      await getWarrantyInvoices();
                    },

                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? WerlogColors.teal.withOpacity(0.1)
                            : Colors.white,

                        borderRadius:
                        BorderRadius.circular(14),

                        border: Border.all(
                          color: selected
                              ? WerlogColors.teal
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [

                          Expanded(
                            child: Text(
                              _mapStatus(status),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? WerlogColors.teal
                                    : Colors.black,
                              ),
                            ),
                          ),

                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: WerlogColors.teal,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
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
                          'Search in invoices...'/*${widget.categoryName}*/,
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
        GestureDetector(
          onTap: (){
            _showFilterSheet();
          },
          child: Container(
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

              _filteredItems.sort((a, b) {
                // Convert dd/MM/yyyy or M/d/yyyy string to DateTime
                DateTime parseDate(String date) {
                  final parts = date.split('/');

                  return DateTime(
                    int.parse(parts[2]), // year
                    int.parse(parts[0]), // month
                    int.parse(parts[1]), // day
                  );
                }

                if (_sortBy == 'Purchase Date') {
                  return parseDate(a.purchaseDate)
                      .compareTo(parseDate(b.purchaseDate));
                } else {
                  return parseDate(a.expiresOn)
                      .compareTo(parseDate(b.expiresOn));
                }
              });
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
        /*const Spacer(),
        Icon(Icons.view_list,
            color: WerlogColors.teal, size: 20),*/
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
          getWarrantyInvoices(); // refresh your API / list
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
              child: Icon(CategoryData.categoryIcons.first,
                  color: Color(CategoryData.catColors.first), size: 26),
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

  Future<void> getWarrantyInvoices() async {
    try {
      final response = await ApiService.postFormData(
        context,
        '${Endpoints.WARRANTY_INVOICES_LIST}',
          fields: {
            "status": selectedStatus
          }
      );

      print('\nSUCCESS => $response');

      final result = response['result']=="1" ? true : false;
      if (result) {

        final List<dynamic> invoicesList = response['data'] ?? [];
        /*final data = response['data'] ?? {};
        final invoicesList = data['invoiceLists'] ?? [];*/

        setState(() {

          // =========================================================
          // MAP API LIST -> WARRANTY ITEMS
          // =========================================================

          CategoryData.electronics.clear();

          for (final item in invoicesList) {
            // print(item);

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

                evidenceUrl: item['evidenceUrl']?.toString() ?? '',

                // items: items['items'],
                items: (item['items'] as List<dynamic>? ?? [])
                    .map(
                      (e) => InvoiceLineItemData(
                    description: e['description']?.toString() ?? '',

                    quantity: (e['quantity'] as num?)?.toInt() ?? 0,

                    unitPrice:
                    (e['unit_price'] ?? e['unitPrice'] ?? 0)
                        .toDouble(),

                    amount:
                    (e['amount'] ?? 0)
                        .toDouble(),
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
        print("All Invoices :: data synced to UI");
        allItems = CategoryData.electronics;

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

  String _mapStatus(String status) {
    switch (status.toUpperCase()) {
      case "":
        return "All";

      case "ACTIVE":
        return "Active";

      case "EXPIRED":
        return "Expired";

      case "COMING_SOON":
        return "Expiring soon";

      default:
        return "Active";
    }
  }
}
