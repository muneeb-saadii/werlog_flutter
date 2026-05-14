import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/general_functions.dart';
import 'category_overview_screen.dart';

// ─────────────────────────────────────────
//  DATA MODELS — replace with API response
// ─────────────────────────────────────────
class WarrantyDashboardData {
  // Stats
  static int totalWarranties = 24;
  static int activeWarranties = 14;
  static int expiringSoonWarranties = 5;
  static int expiredWarranties = 3;
  static int claimedWarranties = 2;

  // Overview percentages
  static double get activePercent =>
      activeWarranties / totalWarranties * 100;
  static double get expiringSoonPercent =>
      expiringSoonWarranties / totalWarranties * 100;
  static double get expiredPercent =>
      expiredWarranties / totalWarranties * 100;
  static double get claimedPercent =>
      claimedWarranties / totalWarranties * 100;

  // Categories
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
  static List<Map<String, dynamic>> categories = [
    {
      'name': 'Electronics',
      'icon': Icons.monitor,
      'active': 5,
      'expiring': 1,
      'expired': 0,
      'color': 0xFF1D9E75,
    },
    {
      'name': 'Home Appliances',
      'icon': Icons.kitchen,
      'active': 4,
      'expiring': 0,
      'expired': 1,
      'color': 0xFF0F2A2E,
    },
    {
      'name': 'Mobile & Tablets',
      'icon': Icons.smartphone,
      'active': 3,
      'expiring': 1,
      'expired': 0,
      'color': 0xFF7B5EA7,
    },
    {
      'name': 'Furniture',
      'icon': Icons.chair,
      'active': 2,
      'expiring': 0,
      'expired': 0,
      'color': 0xFFBA7517,
    },
    {
      'name': 'Vehicles',
      'icon': Icons.directions_car,
      'active': 2,
      'expiring': 0,
      'expired': 0,
      'color': 0xFF1D9E75,
    },
    {
      'name': 'Bikes',
      'icon': Icons.pedal_bike,
      'active': 1,
      'expiring': 0,
      'expired': 0,
      'color': 0xFF0F2A2E,
    },
    {
      'name': 'Kitchen Appliances',
      'icon': Icons.soup_kitchen,
      'active': 2,
      'expiring': 0,
      'expired': 0,
      'color': 0xFFD85A30,
    },
    {
      'name': 'Tools & Equipment',
      'icon': Icons.handyman,
      'active': 1,
      'expiring': 0,
      'expired': 0,
      'color': 0xFF5DCAA5,
    },
  ];
}

class WarrantyDashboardScreen extends StatefulWidget {
  const WarrantyDashboardScreen({super.key});

  @override
  State<WarrantyDashboardScreen> createState() => _WarrantyDashboardScreenState();
}

class _WarrantyDashboardScreenState extends State<WarrantyDashboardScreen> {
  bool showAllCategories = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getWarrantyDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroBanner(context),
                    const SizedBox(height: 16),
                    _buildWarrantyOverview(context),
                    const SizedBox(height: 16),
                    _buildCategoriesSection(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: WerlogColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'My Warranty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: WerlogColors.textPrimary,
              ),
            ),
          ),
          /*IconButton(
            icon: const Icon(Icons.notifications_outlined,
                size: 22, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search,
                size: 22, color: WerlogColors.textPrimary),
            onPressed: () {},
          ),*/
        ],
      ),
    );
  }

  // ── Hero banner with stats ────────────────
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: WerlogGradients.darkHero(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: WerlogColors.darkTeal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Morning, Alex 👋',
              style: WerlogTextStyles.heroTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text("Here's what's happening with your warranties",
              style: WerlogTextStyles.heroSubtitle),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _statChip(Icons.shield_outlined, 'Total',
                    '${WarrantyDashboardData.totalWarranties}', false),
                const SizedBox(width: 10),
                _statChip(Icons.check_circle_outline, 'Active',
                    '${WarrantyDashboardData.activeWarranties}', false,
                    highlight: WerlogColors.teal),
                const SizedBox(width: 10),
                _statChip(Icons.timer_outlined, 'Expiring Soon',
                    '${WarrantyDashboardData.expiringSoonWarranties}', false,
                    highlight: WerlogColors.amber),
                const SizedBox(width: 10),
                _statChip(Icons.cancel_outlined, 'Expired',
                    '${WarrantyDashboardData.expiredWarranties}', false,
                    highlight: WerlogColors.coral),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(
      IconData icon, String label, String value, bool active,
      {Color? highlight}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (highlight ?? Colors.white).withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: highlight ?? Colors.white.withOpacity(0.6), size: 12),
              const SizedBox(width: 4),
              Text(label,
                  style: WerlogTextStyles.balanceSub.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: WerlogTextStyles.balanceAmount.copyWith(fontSize: 22)),
        ],
      ),
    );
  }

  // ── Warranty overview card ────────────────
  Widget _buildWarrantyOverview(BuildContext context) {
    final total = WarrantyDashboardData.totalWarranties.toDouble();
    return Container(
      decoration: BoxDecoration(
        color: WerlogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WerlogColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Warranty Overview',
                  style: WerlogTextStyles.sectionTitle),
              GestureDetector(
                onTap: () {},
                child: Text('View All',
                    style: WerlogTextStyles.link.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  _progressSegment(
                      WerlogColors.teal,
                      WarrantyDashboardData.activeWarranties / total),
                  const SizedBox(width: 2),
                  _progressSegment(
                      WerlogColors.amber,
                      WarrantyDashboardData.expiringSoonWarranties / total),
                  const SizedBox(width: 2),
                  _progressSegment(
                      WerlogColors.coral,
                      WarrantyDashboardData.expiredWarranties / total),
                  const SizedBox(width: 2),
                  _progressSegment(
                      WerlogColors.textTertiary,
                      WarrantyDashboardData.claimedWarranties / total),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _overviewRow(WerlogColors.teal, 'Active', null,
              WarrantyDashboardData.activeWarranties,
              '${WarrantyDashboardData.activePercent.toStringAsFixed(0)}%'),
          _overviewRow(WerlogColors.amber, 'Expiring Soon',
              'Within 90 days',
              WarrantyDashboardData.expiringSoonWarranties,
              '${WarrantyDashboardData.expiringSoonPercent.toStringAsFixed(0)}%'),
          _overviewRow(WerlogColors.coral, 'Expired', null,
              WarrantyDashboardData.expiredWarranties,
              '${WarrantyDashboardData.expiredPercent.toStringAsFixed(0)}%'),
          _overviewRow(WerlogColors.textTertiary, 'Claimed', null,
              WarrantyDashboardData.claimedWarranties,
              '${WarrantyDashboardData.claimedPercent.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _progressSegment(Color color, double flex) {
    final safeFlex = flex.isFinite && !flex.isNaN
        ? (flex * 100).clamp(1, 100).toInt()
        : 1;
    return Expanded(
      flex: safeFlex,
      child: Container(color: color),
    );
  }

  Widget _overviewRow(
      Color color, String label, String? sub, int count, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: WerlogTextStyles.body.copyWith(fontSize: 12)),
                if (sub != null)
                  Text(sub,
                      style: WerlogTextStyles.caption
                          .copyWith(color: WerlogColors.amber)),
              ],
            ),
          ),
          // Dotted line
          Expanded(
            child: CustomPaint(
              painter: _DottedLinePainter(),
              child: const SizedBox(height: 1),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count',
              style:
                  WerlogTextStyles.txTitle.copyWith(fontSize: 13)),
          const SizedBox(width: 12),
          Text(percent,
              style: WerlogTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Categories grid ───────────────────────
  Widget _buildCategoriesSection(BuildContext context) {
    final categories = WarrantyDashboardData.categories;
    final List<Map<String, dynamic>> renderList =
    showAllCategories
        ? categories
        : (categories.length > 7
        ? [...categories.take(7), {'isMore': true}]
        : categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories (${categories.length})',
              style: WerlogTextStyles.sectionTitle,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showAllCategories = true;
                });
              },
              child: Text(
                'View All',
                style: WerlogTextStyles.link.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: renderList.length,
          itemBuilder: (_, i) {
            final item = renderList[i];
            if (item['isMore'] == true) {
              final remaining = categories.length - 7;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    showAllCategories = true;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: WerlogColors.tealSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: WerlogColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+$remaining More',
                        style: WerlogTextStyles.sectionTitle
                            .copyWith(color: WerlogColors.teal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View All',
                        style: WerlogTextStyles.link.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _categoryTile(context, item);
          },
        ),
      ],
    );
  }

  Widget _categoryTile(
      BuildContext context, Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CategoryOverviewScreen(
                  categoryName: cat['name'],
                  categoryIcon: cat['icon'],
                  iconColor: Color(cat['color']),
              catId: cat['id'],
                )),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color(cat['color']).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat['icon'] as IconData,
                  color: Color(cat['color']), size: 22),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final text = cat['name'];

                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: text,
                      style: WerlogTextStyles.txTitle.copyWith(fontSize: 10),
                    ),
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: constraints.maxWidth);

                  final isOverflow = textPainter.didExceedMaxLines ||
                      textPainter.width > constraints.maxWidth;

                  if (isOverflow) {
                    return Marquee(
                      text: text,
                      style: WerlogTextStyles.txTitle.copyWith(fontSize: 10),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 20,
                      velocity: 35,
                      pauseAfterRound: const Duration(seconds: 1),
                      startPadding: 10,
                    );
                  } else {
                    return Text(
                      text,
                      style: WerlogTextStyles.txTitle.copyWith(fontSize: 10),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniDot(WerlogColors.teal, '${cat['active']}'),
                const SizedBox(width: 4),
                _miniDot(WerlogColors.amber, '${cat['expiring']}'),
                const SizedBox(width: 4),
                _miniDot(WerlogColors.coral, '${cat['expired']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 2),
        Text(label,
            style: WerlogTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }

  Widget _moreTile(BuildContext context) {
    final remaining = WarrantyDashboardData.categories.length - 7;
    return GestureDetector(
      onTap: () {
        setState(() {
          showAllCategories = true;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.tealSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+$remaining More',
                style:
                    WerlogTextStyles.sectionTitle.copyWith(color: WerlogColors.teal)),
            const SizedBox(height: 4),
            Text('View All',
                style: WerlogTextStyles.link.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> getWarrantyDetails() async {
    try {
      final response = await ApiService.get(
          context,
          Endpoints.WARRANTY_DASHBOARD_DETAILS,
      );

      print('\nSUCCESS => $response');

      final result = response['result']=="1" ? true : false;
      if(result){
        final data = response['data'];
        final warranty = data['warranty'];
        final categoriesJson = data['categories'] as List;

        final categories = categoriesJson.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return {
            'id': item['id'],
            'name': item['name'],
            'slug': item['slug'],
            'icon': WarrantyDashboardData.categoryIcons[index % WarrantyDashboardData.categoryIcons.length],
            'active': item['active'],
            'expiring': item['comingSoon'],
            'expired': item['expired'],
            'color': WarrantyDashboardData.catColors[index % WarrantyDashboardData.catColors.length],
          };
        }).toList();

        setState(() {
          WarrantyDashboardData.totalWarranties = warranty['total'];
          WarrantyDashboardData.activeWarranties = warranty['active'];
          WarrantyDashboardData.expiringSoonWarranties = warranty['expiringSoon'];
          WarrantyDashboardData.expiredWarranties = warranty['expired'];
          WarrantyDashboardData.claimedWarranties = warranty['claimed'];

          WarrantyDashboardData.categories = categories;
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

// ── Dotted line painter ───────────────────
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WerlogColors.border
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
