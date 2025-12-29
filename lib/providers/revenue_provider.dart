import 'dart:io';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    // Platform-specific API keys
    String apiKey;
    if (Platform.isIOS) {
      apiKey = 'goog_LhywoLvNqUmhmLmpFrsOkDFstVB';
    } else if (Platform.isAndroid) {
      apiKey = 'goog_LhywoLvNqUmhmLmpFrsOkDFstVB';
    } else {
      debugPrint('RevenueCat not supported on this platform');
      _errorMessage = 'Platform not supported';
      notifyListeners();
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));

    await _checkEntitlements();
    await fetchOfferings();

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateCustomerStatus(customerInfo);
    });
  }

  Future<void> fetchOfferings() async {
    try {
      _errorMessage = null;
      notifyListeners();
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      debugPrint("Error fetching offerings: $e");
      _errorMessage = "Error fetching offerings: $e";
    }
    notifyListeners();
  }

  Future<void> _checkEntitlements() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateCustomerStatus(customerInfo);
    } catch (e) {
      debugPrint("Error checking entitlements: $e");
    }
  }

  void _updateCustomerStatus(CustomerInfo customerInfo) {
    // Check for 'lockt Pro' entitlement
    final isPro = customerInfo.entitlements.active.containsKey('lockt Pro');
    if (_isPremium != isPro) {
      _isPremium = isPro;
      notifyListeners();
    }
  }

  Future<bool> purchaseLifetime(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      _updateCustomerStatus(purchaseResult.customerInfo);
      return true;
    } catch (e) {
      debugPrint("Error purchasing package: $e");
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateCustomerStatus(customerInfo);
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
    }
  }
}
