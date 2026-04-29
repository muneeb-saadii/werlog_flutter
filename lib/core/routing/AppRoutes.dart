import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../ui/screens/screen_04_ocr_flow.dart';
import '../../ui/screens/screen_05_invoice_detail.dart';
import '../../ui/screens/screen_06_list_reports_profile.dart';
import '../models/app_models_extended.dart';

class AppRoutes {
  static Future<void> openScanType(
      BuildContext context, {
        ValueChanged<ScanType>? onTypeSelected,
        VoidCallback? onContinue,
        ScanTypeSheetData? data,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ScanTypeSheet(
          data: data,
          onTypeSelected: onTypeSelected,
          onContinue: () {
            Navigator.pop(context); // close sheet
            onContinue?.call();     // trigger external logic
          },
        );
      },
    );
  }
  static Future<void> openScanType_(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 🔥 important
      builder: (_) {
        return const ScanTypeSheet();
      },
    );
  }

  static Future<void> openCameraScreen(
      BuildContext context, {
        VoidCallback? onClose,
        VoidCallback? onCapture,
        VoidCallback? onToggleFlash,
        VoidCallback? onSwitchCamera,
        VoidCallback? onGallery,
      }) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          onClose: onClose,
          onCapture: onCapture,
          onToggleFlash: onToggleFlash,
          onSwitchCamera: onSwitchCamera,
          onGallery: onGallery,
        ),
      ),
    );
  }

  static Future<void> openInvoiceList(
      BuildContext context, {
        InvoiceListData? data,
        int currentTab = 1,
        void Function(InvoiceListItem item)? onItemTap,
        void Function(int tab)? onTabChanged,
      }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceListScreen(
          data: data,
          currentTab: currentTab,
          onItemTap: onItemTap,
          onTabChanged: onTabChanged,
        ),
      ),
    );
  }

  static Future<void> openOcrProcessingScreen(
      BuildContext context, {
        OcrProcessingData? data,
        VoidCallback? onBack,
      }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OcrProcessingScreen(
          data: data,
          onBack: onBack,
        ),
      ),
    );
  }

  static Future<void> openInvoiceList_(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InvoiceListScreen(),
      ),
    );
  }

  static Future<void> openInvoiceDetail_(
    BuildContext context, {
    InvoiceDetailData? data,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(data: data),
      ),
    );
  }

  static Future<void> openReports(
      BuildContext context, {
        ReportsData? data,
        VoidCallback? onExport,
        void Function(int tab)? onTabChanged,
        int currentTab = 3,
      }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsScreen(
          data: data,
          onExport: onExport,
          onTabChanged: onTabChanged,
          currentTab: currentTab,
        ),
      ),
    );
  }

  static Future<void> openProfile(
      BuildContext context, {
        ProfileData? data,
        void Function(SettingRow row)? onSettingTap,
        void Function(int tab)? onTabChanged,
        int currentTab = 4,
      }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          data: data,
          onSettingTap: onSettingTap,
          onTabChanged: onTabChanged,
          currentTab: currentTab,
        ),
      ),
    );
  }

  static Future<void> openInvoiceDetail(
      BuildContext context, {
        InvoiceDetailData? data,
        VoidCallback? onBack,
        VoidCallback? onEdit,
        VoidCallback? onShare,
        VoidCallback? onMore,
        VoidCallback? onPrimaryAction,
        VoidCallback? onSecondaryAction,
        void Function(int tab)? onTabChanged,
        int currentTab = 1,
      }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          data: data,
          onBack: onBack,
          onEdit: onEdit,
          onShare: onShare,
          onMore: onMore,
          onPrimaryAction: onPrimaryAction,
          onSecondaryAction: onSecondaryAction,
          onTabChanged: onTabChanged,
          currentTab: currentTab,
        ),
      ),
    );
  }
}