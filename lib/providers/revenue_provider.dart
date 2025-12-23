import 'dart:io';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';


class RevenueProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> init() async {
    // Platform-specific API keys
    String apiKey;
    if (Platform.isIOS) {
      apiKey = 'test_DJwfOkWXEabCAHraSGnxtJRBsel';
    } else if (Platform.isAndroid) {
      apiKey = 'test_DJwfOkWXEabCAHraSGnxtJRBsel';
    } else {
      debugPrint('RevenueCat not supported on this platform');
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));

    await _checkEntitlements();

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateCustomerStatus(customerInfo);
    });
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

  Future<void> purchaseLifetime() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        // Assuming the first package is the one we want, or look for specific identifier
        // For now, let's take the first available package which should be the lifetime one if configured correctly
        final package = offerings.current!.availablePackages.first;
        
        final purchaseResult = await Purchases.purchasePackage(package);
        _updateCustomerStatus(purchaseResult.customerInfo);
      } else {
        debugPrint("No offerings available");
      }
    } catch (e) {
      debugPrint("Error purchasing package: $e");
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
