import 'dart:async';
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

  /// Guards against calling init() multiple times
  bool _isInitialized = false;

  /// Stored stream subscription so we can manage its lifecycle
  StreamSubscription<ServiceNotificationEvent>? _notificationSubscription;

  /// Deduplication: track when we last processed a notification content hash
  /// to prevent firing the same notification twice, while allowing new ones.
  /// Using DateTime instead of Future.delayed prevents background suspension issues.
  final Map<String, DateTime> _recentHashes = {};

  /// Bank keywords for Ethiopian financial institutions
  static const List<String> _bankKeywords = [
    'cbe', 'telebirr', 'awash', 'dashen', 'cbo', 'coop', 'abyssinia', 'boa',
    'wegagen', 'zemen', 'nib', 'hibret', 'oromia', 'amhara', 'bank',
    '1000', '127', 'cbemobilebanking', 'ethiotelecom',
  ];

  /// Transaction action words
  static const List<String> _actionWords = [
    'received', 'receive', 'transfer', 'transferred', 'paid', 'sent',
    'credit', 'credited', 'debit', 'debited', 'withdraw', 'withdrawn',
    'payment', 'deposit', 'deposited', 'deducted', 'recharg', 'topped',
  ];

  /// Ethiopian currency indicators
  static const List<String> _currencyWords = ['birr', 'br', 'etb'];

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // Prevent double-initialization which kills the stream
    if (_isInitialized) {
      log('[BankNotif] Already initialized, skipping.');
      return;
    }
    _isInitialized = true;

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

    await _startListening();
    log('[BankNotif] Initialization complete.');
  }

  void _onNotificationTap(String? payload) {
    if (navigatorKey?.currentContext != null) {
      Navigator.pushNamed(
          navigatorKey!.currentContext!, AppRoutes.addExpenseScreen, arguments: payload);
    }
  }

  Future<void> _startListening() async {
    // Cancel any existing subscription before creating a new one
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    try {
      bool isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted) {
        log('[BankNotif] Permission not granted. Requesting...');
        await NotificationListenerService.requestPermission();
        // Re-check after request
        isGranted = await NotificationListenerService.isPermissionGranted();
        if (!isGranted) {
          log('[BankNotif] Permission still not granted after request.');
          // Schedule a retry after 30 seconds
          _scheduleRetry();
          return;
        }
      }

      _notificationSubscription = NotificationListenerService.notificationsStream.listen(
        (event) {
          _handleIncomingNotification(event);
        },
        onError: (error) {
          log('[BankNotif] Stream error: $error. Scheduling reconnect...');
          _scheduleRetry();
        },
        onDone: () {
          log('[BankNotif] Stream closed unexpectedly. Scheduling reconnect...');
          _scheduleRetry();
        },
        cancelOnError: false, // Keep listening even if individual events error
      );
      log('[BankNotif] Notification stream active and listening.');
    } catch (e) {
      log('[BankNotif] Error starting listener: $e. Scheduling retry...');
      _scheduleRetry();
    }
  }

  /// Automatically retry connecting to the notification stream
  void _scheduleRetry() {
    Future.delayed(const Duration(seconds: 15), () {
      log('[BankNotif] Retrying stream connection...');
      _startListening();
    });
  }

  /// Generate a simple hash for deduplication
  String _contentHash(String title, String content) {
    return '$title|$content';
  }

  /// No longer using Future.delayed for cleanup to avoid isolate suspension bugs.
  /// We handle it manually in _handleIncomingNotification length checks.
  void _scheduleHashCleanup() {
    if (_recentHashes.length > 50) {
      // Remove entries older than 5 minutes to prevent memory leak
      final now = DateTime.now();
      _recentHashes.removeWhere((key, time) => now.difference(time).inMinutes > 5);
    }
  }

  void _handleIncomingNotification(ServiceNotificationEvent event) {
    // Ignore notification removal/dismissal events
    if (event.hasRemoved == true) return;

    final originalTitle = event.title ?? '';
    final originalContent = event.content ?? '';
    final title = originalTitle.toLowerCase().trim();
    final content = originalContent.toLowerCase().trim();
    final packageName = (event.packageName ?? '').toLowerCase();

    // Ignore empty or junk notifications
    if (originalContent.trim().isEmpty) return;
    if (content.contains('checking for') || content.contains('looking for')) return;

    // Ignore our own app's notifications to prevent infinite loops
    if (packageName.contains('smartexpensetracker') ||
        packageName.contains('fainance_planer') ||
        packageName.contains('track_expense')) {
      return;
    }

    // Deduplication using timestamp to survive background isolate suspension
    final hash = _contentHash(title, content);
    final now = DateTime.now();
    
    if (_recentHashes.containsKey(hash)) {
      final lastProcessed = _recentHashes[hash]!;
      // Block identical notifications if they arrive within 20 seconds.
      if (now.difference(lastProcessed).inSeconds < 20) {
        log('[BankNotif] Duplicate skipped: $hash');
        return;
      }
    }

    log('[BankNotif] Incoming => Pkg: $packageName | Title: $originalTitle | Content: $originalContent');

    bool isBankNotification = false;

    // 1. Check package name and title against known bank keywords
    for (final kw in _bankKeywords) {
      if (packageName.contains(kw) || title.contains(kw)) {
        isBankNotification = true;
        break;
      }
    }

    // 2. Check if it's from the default SMS app (com.google.android.apps.messaging, com.samsung.android.messaging, etc.)
    if (!isBankNotification && 
        (packageName.contains('messaging') || packageName.contains('sms') || packageName.contains('mms'))) {
      // SMS from banks often have short sender names or numbers
      // Check content for transaction indicators
      bool hasAction = _actionWords.any((a) => content.contains(a));
      bool hasCurrency = _currencyWords.any((c) => content.contains(c));
      bool hasAmount = RegExp(r'\d+[.,]?\d*').hasMatch(content);

      if (hasAction && (hasCurrency || hasAmount)) {
        isBankNotification = true;
      } else if (title.contains('1000') || title.contains('127') || title.contains('cbe') || title.contains('telebirr')) {
        // Fallback for grouped SMS: If the title is explicitly the bank's shortcode/name,
        // it's almost certainly a bank SMS even if the content is "2 new messages"
        isBankNotification = true;
      }
    }

    // 3. Fallback: content-only heuristic for any notification source
    if (!isBankNotification) {
      bool hasAction = _actionWords.any((a) => content.contains(a));
      bool hasCurrency = _currencyWords.any((c) => content.contains(c));

      if (hasAction && hasCurrency) {
        isBankNotification = true;
      }
    }

    // 4. Fire the local prompt if verified
    if (isBankNotification) {
      // Mark as processed to prevent duplicates
      _recentHashes[hash] = now;
      _scheduleHashCleanup();

      log('[BankNotif] ✅ MATCH! Firing local prompt.');
      _fireLocalPrompt(originalTitle, originalContent);
    }
  }

  Future<void> _fireLocalPrompt(String bankTitle, String originalContent) async {
    // Generate a static ID based on the bank name to organize notifications
    // and replace the previous one instead of endlessly stacking them.
    final int notifId = bankTitle.hashCode.abs() % 100000;

    // Force cancel the old notification first to ensure the system treats the new one as fresh
    // and plays the high-priority heads-up alert again for subsequent transactions.
    await _localNotificationsPlugin.cancel(id: notifId);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bank_tracker_channel',
      'Bank Transactions',
      channelDescription: 'Prompts to record bank transactions',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF5A4FCF),
      ongoing: true, // Remains visible
      autoCancel: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: notifId, // Use consistent ID
      title: 'New Transaction Detected',
      body: 'Tap to record this transaction from $bankTitle in your app.',
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode({'title': bankTitle, 'content': originalContent}),
    );
  }
}
