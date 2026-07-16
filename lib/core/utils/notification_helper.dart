import 'package:flutter/material.dart';

class CustomNotification {
  static void showSuccess(BuildContext context, String message, {String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message: message,
      title: title ?? (isDark ? "نجاح" : "Success"),
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      backgroundColor: isDark ? const Color(0xFF142C18) : const Color(0xFFE8F5E9),
      textColor: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message: message,
      title: title ?? (isDark ? "خطأ" : "Error"),
      icon: Icons.error_outline,
      iconColor: Colors.red,
      backgroundColor: isDark ? const Color(0xFF2C1414) : const Color(0xFFFFEBEE),
      textColor: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFB71C1C),
    );
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message: message,
      title: title ?? (isDark ? "تنبيه" : "Warning"),
      icon: Icons.warning_amber_outlined,
      iconColor: Colors.orange,
      backgroundColor: isDark ? const Color(0xFF2C2214) : const Color(0xFFFFF3E0),
      textColor: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
    );
  }

  static void showInfo(BuildContext context, String message, {String? title, SnackBarAction? action}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message: message,
      title: title,
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      backgroundColor: isDark ? const Color(0xFF141F2C) : const Color(0xFFE3F2FD),
      textColor: isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1),
      action: action,
    );
  }

  static void showPremium(BuildContext context, String message, {String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message: message,
      title: title ?? (isDark ? "عضوية ذهبية" : "Premium Gold"),
      icon: Icons.stars_outlined,
      iconColor: Colors.amber.shade700,
      backgroundColor: isDark ? const Color(0xFF2C2614) : const Color(0xFFFFFDE7),
      textColor: isDark ? const Color(0xFFFFE082) : const Color(0xFF7F6000),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    String? title,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Styled Icon container
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Message text
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    Text(
                      message,
                      style: TextStyle(
                        color: textColor.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Undo or action button
              if (action != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    action.onPressed();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: iconColor.withOpacity(0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    action.label,
                    style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
