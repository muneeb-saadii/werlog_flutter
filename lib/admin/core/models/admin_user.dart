import 'package:flutter/material.dart';

/// Lifecycle state of a user account.
enum UserStatus { active, suspended, deleted }

/// Subscription tier of a user account.
enum UserPlan { free, pro, business }

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }
}

extension UserPlanX on UserPlan {
  String get label {
    switch (this) {
      case UserPlan.free:
        return 'FREE';
      case UserPlan.pro:
        return 'PRO';
      case UserPlan.business:
        return 'BUSINESS';
    }
  }
}

/// A single admin-visible user record, as shown in the Users list
/// and the User details screen.
class AdminUser {
  final String id;
  final String name;
  final String email;
  final UserStatus status;
  final UserPlan plan;
  final String role;
  final bool verified;
  final DateTime joined;
  final DateTime lastLogin;
  final String subscriptionSummary;
  final Color avatarColor;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.plan,
    required this.role,
    required this.verified,
    required this.joined,
    required this.lastLogin,
    required this.subscriptionSummary,
    required this.avatarColor,
  });

  /// Two-letter initials derived from the display name, e.g. "Haseeb Ihsan" -> "HI".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length < 2 ? p.length : 2).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Shortened id for display, e.g. "c1ee...50e3".
  String get shortId {
    if (id.length <= 9) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  String get lastLoginLabel => _relativeTime(lastLogin);

  String get joinedLabel => _formatDate(joined);

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
