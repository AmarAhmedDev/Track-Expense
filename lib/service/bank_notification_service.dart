import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../routes/app_routes.dart';

class BankNotificationService {
  static final BankNotificationService _instance = BankNotificationService._internal();

  factory BankNotificationService() {
    return _instance;
  }

  BankNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _onNotificationTap(details.payload);
      },
    );

    await _localNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _startListening();
  }

  void _onNotificationTap(String? payload) {
    if (navigatorKey?.currentContext != null) {
      // Decode payload if needed to extract amount/type
      Navigator.pushNamed(
          navigatorKey!.currentContext!, AppRoutes.addExpenseScreen, arguments: payload);
    }
  }

  Future<void> _startListening() async {
    try {
      bool isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted) {
        log("Notification listener permission not granted.");
        // We shouldn't request permission automatically without prompting user, 
        // but for now, let's request it or leave it to UI.
        await NotificationListenerService.requestPermission();
      }

      NotificationListenerService.notificationsStream.listen((event) {
        _handleIncomingNotification(event);
      });
      log("Started listening to notifications");
    } catch (e) {
      log("Error starting notification listener: $e");
    }
  }

  void _handleIncomingNotification(ServiceNotificationEvent event) {
    // Ignore notification dismissal events to prevent duplicate prompts
    if (event.hasRemoved == true) return;

    final originalTitle = event.title ?? '';
    final originalContent = event.content ?? '';
    final title = originalTitle.toLowerCase();
    final content = originalContent.toLowerCase();
    final packageName = event.packageName ?? '';

    // Ignore empty content or notifications that are just "checking for messages"
    if (originalContent.isEmpty || content.contains('checking for')) return;

    log("Received notification: Title: '$originalTitle', Content: '$originalContent', Package: '$packageName'");

    bool isBankNotification = false;

    // 1. Package name or Title exact matches for known Ethiopian financial institutions
    final bankKeywords = [
      'cbe', 'telebirr', 'awash', 'dashen', 'cbo', 'coop', 'abyssinia', 'boa', 
      'wegagen', 'zemen', 'nib', 'hibret', 'oromia', 'amhara', 'bank', '1000', '127'
    ];

    for (final kw in bankKeywords) {
      if (packageName.toLowerCase().contains(kw) || title.contains(kw)) {
        isBankNotification = true;
        break;
      }
    }

    // 2. Action + Currency heuristic (crucial for SMS where title might just be a phone number)
    if (!isBankNotification) {
      final actions = [
        'received', 'receive', 'transfer', 'transferred', 'paid', 'sent', 
        'credit', 'credited', 'debit', 'debited', 'withdraw', 'withdrawn', 
        'payment', 'deposit', 'deducted'
      ];
      final currencies = ['birr', 'br', 'etb'];
      
      bool hasAction = actions.any((a) => content.contains(a));
      bool hasCurrency = currencies.any((c) => content.contains(c));
      
      // We also check for number patterns like "100.00" just to be sure it's a transaction
      bool hasNumbers = RegExp(r'\d+').hasMatch(content);

      if (hasAction && (hasCurrency || hasNumbers)) {
        isBankNotification = true;
      }
    }

    // 3. Final verification to ensure it's a transaction before firing
    if (isBankNotification) {
      final confirmTokens = [
        'birr', 'br', 'etb', 'sent', 'paid', 'transfer', 'received', 'credit', 
        'credited', 'debit', 'debited', 'withdraw', 'withdrawn', 'deposit', 'deducted'
      ];
      
      if (confirmTokens.any((t) => content.contains(t))) {
         log("Bank transaction verified. Firing local prompt.");
         _fireLocalPrompt(originalTitle, originalContent);
      }
    }
  }

  Future<void> _fireLocalPrompt(String bankTitle, String originalContent) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bank_tracker_channel',
      'Bank Transactions',
      channelDescription: 'Prompts to record bank transactions',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF5A4FCF),
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'New Transaction Detected',
      body: 'Tap to record this transaction from $bankTitle in your app.',
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode({'title': bankTitle, 'content': originalContent}),
    );
  }
}
