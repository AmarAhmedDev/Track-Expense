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
    final originalTitle = event.title ?? '';
    final originalContent = event.content ?? '';
    final title = originalTitle.toLowerCase();
    final content = originalContent.toLowerCase();
    final packageName = event.packageName ?? '';

    log("Received notification: Title: '$originalTitle', Content: '$originalContent', Package: '$packageName'");

    // Filter rules for Ethiopian Banks (CBE, Awash, Dashen, Telebirr, etc.)
    bool isBankNotification = false;

    if (packageName.toLowerCase().contains('cbe') || 
        packageName.contains('telebirr') || 
        title.contains('cbe') || 
        title.contains('awash') ||
        title.contains('dashen') ||
        title.contains('telebirr') ||
        title.contains('cbo') ||
        title.contains('bank')) {
      isBankNotification = true;
    }

    if (!isBankNotification && (content.contains('birr') || content.contains('br') || content.contains('etb'))) {
       // Heuristic: If it has Birr/Br/ETB and keywords like "received", "transferred", "paid"
       if (content.contains('received') || content.contains('transfer') || content.contains('paid') || content.contains('sent') || content.contains('credit') || content.contains('recharg') || content.contains('debit')) {
         isBankNotification = true;
       }
    }

    if (isBankNotification) {
      log("Matches Bank Filter! Checking keywords...");
      if (content.contains('birr') || content.contains('br') || content.contains('etb') ||
          content.contains('sent') || content.contains('paid') || content.contains('transfer') || content.contains('received') || content.contains('credit') || content.contains('debit') || content.contains('withdrawn')) {
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
