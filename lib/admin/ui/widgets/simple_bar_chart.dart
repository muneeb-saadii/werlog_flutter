import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Lightweight bar chart used for the "Signups" card, drawn with plain
/// Containers so no charting package is required.
class SimpleBarChart extends StatelessWidget {
  final List<int> values;
  final double height;

  const SimpleBarChart({super.key, required this.values, this.height = 110});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final fraction = maxVal == 0 ? 0.0 : v / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FractionallySizedBox(
                heightFactor: 0.15 + fraction * 0.85,
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accentGreen,
                        Color(0xFF7FD3A6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
