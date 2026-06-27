import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wellness/core/utils/general_functions.dart';

import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shared_pref_helper.dart';

// ════════════════════════════════════════════════════════════════════
//  Currency model
// ════════════════════════════════════════════════════════════════════
class CurrencyItem {
  final String id;       // unique identifier used to track selection
  final String code;     // ISO 4217 e.g. "USD"
  final String symbol;   // e.g. "$"
  final String name;     // e.g. "US Dollar"
  final String country;  // e.g. "United States"
  final String region;   // e.g. "Americas"

  const CurrencyItem({
    required this.id,
    required this.code,
    required this.symbol,
    required this.name,
    required this.country,
    required this.region,
  });
}

// ════════════════════════════════════════════════════════════════════
//  Built-in currency list  (extend as needed)
// ════════════════════════════════════════════════════════════════════
const List<CurrencyItem> _kCurrencies = [
  CurrencyItem(id:'usd', code:'USD', symbol:'\$',  name:'US Dollar',          country:'United States',    region:'Americas'),
  CurrencyItem(id:'eur', code:'EUR', symbol:'€',   name:'Euro',               country:'Eurozone',         region:'Europe'),
  CurrencyItem(id:'gbp', code:'GBP', symbol:'£',   name:'British Pound',      country:'United Kingdom',   region:'Europe'),
  CurrencyItem(id:'pkr', code:'PKR', symbol:'₨',   name:'Pakistani Rupee',    country:'Pakistan',         region:'Asia'),
  CurrencyItem(id:'inr', code:'INR', symbol:'₹',   name:'Indian Rupee',       country:'India',            region:'Asia'),
  CurrencyItem(id:'aed', code:'AED', symbol:'د.إ', name:'UAE Dirham',         country:'United Arab Emirates', region:'Middle East'),
  CurrencyItem(id:'sar', code:'SAR', symbol:'﷼',   name:'Saudi Riyal',        country:'Saudi Arabia',     region:'Middle East'),
  CurrencyItem(id:'cad', code:'CAD', symbol:'CA\$',name:'Canadian Dollar',    country:'Canada',           region:'Americas'),
  CurrencyItem(id:'aud', code:'AUD', symbol:'A\$', name:'Australian Dollar',  country:'Australia',        region:'Oceania'),
  CurrencyItem(id:'jpy', code:'JPY', symbol:'¥',   name:'Japanese Yen',       country:'Japan',            region:'Asia'),
  CurrencyItem(id:'cny', code:'CNY', symbol:'¥',   name:'Chinese Yuan',       country:'China',            region:'Asia'),
  CurrencyItem(id:'chf', code:'CHF', symbol:'Fr',  name:'Swiss Franc',        country:'Switzerland',      region:'Europe'),
  CurrencyItem(id:'sgd', code:'SGD', symbol:'S\$', name:'Singapore Dollar',   country:'Singapore',        region:'Asia'),
  CurrencyItem(id:'myr', code:'MYR', symbol:'RM',  name:'Malaysian Ringgit',  country:'Malaysia',         region:'Asia'),
  CurrencyItem(id:'bdt', code:'BDT', symbol:'৳',   name:'Bangladeshi Taka',   country:'Bangladesh',       region:'Asia'),
  CurrencyItem(id:'qar', code:'QAR', symbol:'﷼',   name:'Qatari Riyal',       country:'Qatar',            region:'Middle East'),
  CurrencyItem(id:'kwd', code:'KWD', symbol:'KD',  name:'Kuwaiti Dinar',      country:'Kuwait',           region:'Middle East'),
  CurrencyItem(id:'omr', code:'OMR', symbol:'﷼',   name:'Omani Rial',         country:'Oman',             region:'Middle East'),
  CurrencyItem(id:'brl', code:'BRL', symbol:'R\$', name:'Brazilian Real',     country:'Brazil',           region:'Americas'),
  CurrencyItem(id:'zar', code:'ZAR', symbol:'R',   name:'South African Rand', country:'South Africa',     region:'Africa'),
  CurrencyItem(id:'nzd', code:'NZD', symbol:'NZ\$',name:'New Zealand Dollar', country:'New Zealand',      region:'Oceania'),
  CurrencyItem(id:'nok', code:'NOK', symbol:'kr',  name:'Norwegian Krone',    country:'Norway',           region:'Europe'),
  CurrencyItem(id:'sek', code:'SEK', symbol:'kr',  name:'Swedish Krona',      country:'Sweden',           region:'Europe'),
  CurrencyItem(id:'dkk', code:'DKK', symbol:'kr',  name:'Danish Krone',       country:'Denmark',          region:'Europe'),
  CurrencyItem(id:'mxn', code:'MXN', symbol:'Mex\$',name:'Mexican Peso',      country:'Mexico',           region:'Americas'),
  CurrencyItem(id:'php', code:'PHP', symbol:'₱',   name:'Philippine Peso',    country:'Philippines',      region:'Asia'),
  CurrencyItem(id:'thb', code:'THB', symbol:'฿',   name:'Thai Baht',          country:'Thailand',         region:'Asia'),
  CurrencyItem(id:'idr', code:'IDR', symbol:'Rp',  name:'Indonesian Rupiah',  country:'Indonesia',        region:'Asia'),
  CurrencyItem(id:'try', code:'TRY', symbol:'₺',   name:'Turkish Lira',       country:'Turkey',           region:'Europe'),
  CurrencyItem(id:'egp', code:'EGP', symbol:'E£',  name:'Egyptian Pound',     country:'Egypt',            region:'Africa'),
];

// ════════════════════════════════════════════════════════════════════
//  CurrencyScreen
//
//  How to call — no params needed:
//    Navigator.push(context,
//      MaterialPageRoute(builder: (_) => const CurrencyScreen()));
//
//  How to read the saved symbol anywhere:
//    final symbol = await SharedPrefHelper.getSelectedCurrencySymbol();
//    final code   = await SharedPrefHelper.getString(SharedPrefHelper.selectedCurrencyCode);
// ════════════════════════════════════════════════════════════════════
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen>
    with SingleTickerProviderStateMixin {

  final _searchCtrl = TextEditingController();
  String _query     = '';
  String? _selectedId;   // id of currently-selected currency

  late final AnimationController _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _loadSaved();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _checkAnim.dispose();
    super.dispose();
  }

  // ── Load previously saved selection ──────────────────────────────
  Future<void> _loadSaved() async {
    final saved = await SharedPrefHelper.getString(
        SharedPrefHelper.selectedCurrencyId);
    if (saved != null && saved.isNotEmpty) {
      setState(() => _selectedId = saved);
    }
  }

  // ── Save selection ────────────────────────────────────────────────
  Future<void> _select(CurrencyItem c) async {
    HapticFeedback.lightImpact();
    setState(() => _selectedId = c.id);
    _checkAnim.forward(from: 0);

    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencyId,     c.id);
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencySymbol, c.symbol);
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencyCode,   c.code);
    await SharedPrefHelper.saveString(
        SharedPrefHelper.selectedCurrencyName,   c.name);
    await GeneralFunctions.getCurrencySymbol();

    _saveProfile(c);
  }

  Future<void> _saveProfile(CurrencyItem c) async {

    // setState(() => _saving = true);

    try {

      final response = await ApiService.postFormData(
        context,
        Endpoints.UPDATE_USER_PROFILE,
        // _pickedImage!,
        // 'file',
        fields: {'currency': c.code},
      );

      final result = response['result'] == "1";

      if (result && mounted) {

        // final updated = _user!.copyWith(fullName: name);
        // await ProfilePrefs.save(updated);
        // setState(() {
        //   _user = updated;
        //   _pickedImage = null;
        //   _saving = false;
        // });
        // _showSnack('Profile updated successfully!');
        // Navigator.of(context).pop();
      } else {
        // setState(() => _saving = false);
        // _showSnack('Update failed. Please try again.', isError: true);
      }
    } catch (e) {
      // setState(() => _saving = false);
      // _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) Navigator.pop(context, c);
      GeneralFunctions.resetAppState();
    }
  }

  // ── Filtered list ─────────────────────────────────────────────────
  List<CurrencyItem> get _filtered {
    if (_query.isEmpty) return _kCurrencies;
    final q = _query.toLowerCase();
    return _kCurrencies.where((c) =>
      c.name.toLowerCase().contains(q)    ||
      c.code.toLowerCase().contains(q)    ||
      c.symbol.toLowerCase().contains(q)  ||
      c.country.toLowerCase().contains(q)
    ).toList();
  }

  // ── Grouped by region ─────────────────────────────────────────────
  Map<String, List<CurrencyItem>> get _grouped {
    final map = <String, List<CurrencyItem>>{};
    for (final c in _filtered) {
      map.putIfAbsent(c.region, () => []).add(c);
    }
    return map;
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final regions = grouped.keys.toList()..sort();

    // Flatten to a list of either region headers or currency items
    final items = <dynamic>[];
    for (final region in regions) {
      items.add(region);           // String = section header
      items.addAll(grouped[region]!);
    }

    return Scaffold(
      backgroundColor: WerlogColors.background,
      body: SafeArea(
        child: Column(children: [

          // ── App bar ───────────────────────────────────────────────
          _buildAppBar(),

          // ── Search bar ────────────────────────────────────────────
          _buildSearchBar(),

          // ── Selected banner ───────────────────────────────────────
          if (_selectedId != null) _buildSelectedBanner(),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item is String) return _buildRegionHeader(item);
                      return _buildCurrencyTile(item as CurrencyItem);
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: WerlogColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: WerlogColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text('Select Currency',
              textAlign: TextAlign.center,
              style: WerlogTextStyles.pageTitle),
        ),
        const SizedBox(width: 48), // balance the back button
      ]),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WerlogColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded,
              color: WerlogColors.textTertiary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: WerlogTextStyles.txTitle.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search currency, code or country…',
                hintStyle: WerlogTextStyles.captionSmall
                    .copyWith(fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close_rounded,
                    color: WerlogColors.textTertiary, size: 18),
              ),
            )
          else
            const SizedBox(width: 14),
        ]),
      ),
    );
  }

  // ── Selected banner ───────────────────────────────────────────────
  Widget _buildSelectedBanner() {
    final sel = _kCurrencies.firstWhere(
        (c) => c.id == _selectedId,
        orElse: () => _kCurrencies.first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WerlogColors.teal.withOpacity(0.08),
              WerlogColors.teal.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: WerlogColors.teal.withOpacity(0.2), width: 0.8),
        ),
        child: Row(children: [
          // Symbol bubble
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: WerlogColors.teal,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(sel.symbol,
                style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 14,
                  fontWeight: FontWeight.w600, color: Colors.white,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current: ${sel.name}',
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: WerlogColors.teal,
                  )),
              Text('${sel.code}  ·  ${sel.country}',
                  style: WerlogTextStyles.captionSmall),
            ],
          )),
          const Icon(Icons.check_circle_rounded,
              color: WerlogColors.teal, size: 18),
        ]),
      ),
    );
  }

  // ── Region section header ─────────────────────────────────────────
  Widget _buildRegionHeader(String region) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(children: [
        Text(region.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'DMSans', fontSize: 9,
              fontWeight: FontWeight.w600,
              color: WerlogColors.textTertiary,
              letterSpacing: 1.2,
            )),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 0.5,
            color: WerlogColors.borderLight)),
      ]),
    );
  }

  // ── Currency row ──────────────────────────────────────────────────
  Widget _buildCurrencyTile(CurrencyItem c) {
    final isSelected = c.id == _selectedId;

    return GestureDetector(
      onTap: () => _select(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? WerlogColors.teal.withOpacity(0.06)
              : WerlogColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? WerlogColors.teal.withOpacity(0.3)
                : WerlogColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: WerlogColors.teal.withOpacity(0.08),
                  blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02),
                  blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [

            // Symbol bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? WerlogColors.teal
                    : WerlogColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? WerlogColors.teal
                      : WerlogColors.border,
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Text(c.symbol,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: c.symbol.length > 2 ? 10 : 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : WerlogColors.textPrimary,
                  )),
            ),

            const SizedBox(width: 12),

            // Name + details
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? WerlogColors.teal
                          : WerlogColors.textPrimary,
                    )),
                const SizedBox(height: 3),
                Row(children: [
                  // Code badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? WerlogColors.teal.withOpacity(0.12)
                          : WerlogColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(c.code,
                        style: TextStyle(
                          fontFamily: 'DMSans', fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? WerlogColors.teal
                              : WerlogColors.textTertiary,
                        )),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(c.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WerlogTextStyles.captionSmall),
                  ),
                ]),
              ],
            )),

            // Check / chevron
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      key: ValueKey('check'),
                      color: WerlogColors.teal, size: 20)
                  : const Icon(Icons.chevron_right_rounded,
                      key: ValueKey('chevron'),
                      color: WerlogColors.textTertiary, size: 20),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: WerlogColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.search_off_rounded,
              color: WerlogColors.textTertiary, size: 26),
        ),
        const SizedBox(height: 14),
        Text('No results for "$_query"',
            style: WerlogTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text('Try a different name, code or country.',
            style: WerlogTextStyles.captionSmall),
      ]),
    );
  }
}
