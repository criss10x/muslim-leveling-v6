import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for premium ("Pro") entitlement.
///
/// v1: backed by a local dev toggle so the whole cosmetic system can be
/// built and demoed without billing. A later billing-only project swaps the
/// implementation for RevenueCat — consumers read [isPro] and never change.
class EntitlementService {
  static const _key = 'entitlement_pro_dev';
  static bool _isPro = false;

  static final ValueNotifier<bool> proStatus = ValueNotifier(false);

  static bool get isPro => _isPro;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isPro = p.getBool(_key) ?? false;
    proStatus.value = _isPro;
  }

  /// DEV ONLY — flips the local Pro flag. Replaced by real billing later.
  static Future<void> setProDev(bool value) async {
    _isPro = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, value);
    proStatus.value = value;
  }
}
