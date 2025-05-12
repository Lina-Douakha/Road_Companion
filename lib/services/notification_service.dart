import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// This function must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase first before doing anything else
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isFlutterLocalNotificationsInitialized = false;
  StreamSubscription? _requestSubscription;

  // Android notification channel IDs
  static const String _highImportanceChannelId = 'high_importance_channel';
  static const String _serviceRequestsChannelId = 'service_requests_channel';

  Future<void> initialize() async {
    print("NotificationService: Initializing...");

    // Make sure this is set BEFORE any other Firebase Messaging code
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions first
    await _requestPermission();

    // Set up notification channels and initialize local notifications
    await setupFlutterNotifications();

    // Set up foreground and background message handlers
    await _setupMessageHandlers();

    // Get the token and save it
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    await _saveTokenToFirestore(token);

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Set up Firestore listeners after everything else is ready
    await _setupFirestoreListeners();

    print("NotificationService: Initialization complete");
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': _getPlatformInfo(),
        });
        print('FCM token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        print('Error saving FCM token: $e');
        // If update fails, document might not exist, try set instead
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'platform': _getPlatformInfo(),
          }, SetOptions(merge: true));
          print('FCM token saved with set operation');
        } catch (setError) {
          print('Error with set operation: $setError');
        }
      }
    } else {
      print('Cannot save FCM token: User not logged in');
    }
  }

  String _getPlatformInfo() {
    // In a real app, you'd use Platform.isIOS, Platform.isAndroid, etc.
    // For simplicity, we're returning a placeholder
    return 'android'; // Replace with actual platform detection
  }

  Future<void> _setupFirestoreListeners() async {
    print("Setting up Firestore listeners...");
    final user = _auth.currentUser;
    if (user == null) {
      print("No user logged in, skipping Firestore listener setup");
      return;
    }

    print("Current user ID: ${user.uid}");

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print("User document does not exist in Firestore");
        return;
      }

      final userData = userDoc.data();
      print("User data: $userData");

      if (userData != null) {
        print("User role: ${userData['Role']}");

        if (userData['Role'] == 'towing_service' || userData['Role'] == 'mechanic' || userData['Role'] == 'parts_supplier') {
          print('Setting up Firestore listener for service provider: ${user.uid}');

          // Cancel existing subscription if any
          _requestSubscription?.cancel();

          // Set up new subscription
          _requestSubscription = _firestore
              .collection('Service_requests')
              .where('providerID', isEqualTo: user.uid)
              .snapshots()
              .listen((snapshot) {
            print("Received Firestore snapshot with ${snapshot.docs.length} documents");
            _handleNewServiceRequests(snapshot);
          }, onError: (error) {
            print("Error in Firestore listener: $error");
          });

          print("Firestore listener set up successfully");
        } else {
          print("User is not a provider, no need for service request notifications");
        }
      }
    } catch (e) {
      print("Error setting up Firestore listener: $e");
    }
  }

  void _handleNewServiceRequests(QuerySnapshot snapshot) {
    print("Processing ${snapshot.docChanges.length} document changes");

    for (var change in snapshot.docChanges) {
      print("Document change type: ${change.type}");
      print("Document ID: ${change.doc.id}");

      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final bool alreadyNotified = data['notified'] == true;
          print("Document already notified: $alreadyNotified");

          if (!alreadyNotified) {
            final clientName = data['clientName'] ?? 'A client';
            print("Showing notification for client: $clientName");

            // Show local notification
            _showLocalServiceRequestNotification(
              title: 'New Service Request',
              body: '$clientName has requested your service',
              payload: change.doc.id,
            );

            // Also send a FCM message to ensure delivery in background
            _sendBackgroundNotification(
              title: 'New Service Request',
              body: '$clientName has requested your service',
              requestId: change.doc.id,
            );

            // Mark as notified
            try {
              _firestore.collection('Service_requests').doc(change.doc.id).update({
                'notified': true,
                'notifiedAt': FieldValue.serverTimestamp(),
              });
              print("Document marked as notified");
            } catch (e) {
              print("Error updating document: $e");
            }
          }
        }
      }
    }
  }

  Future<void> _sendBackgroundNotification({
    required String title,
    required String body,
    required String requestId,
  }) async {
    // In a real implementation, you would call a Cloud Function or use your backend
    // to send an FCM notification to the specific device token

    print("Would send FCM notification through backend: $title - $body - $requestId");

    // This is a placeholder for where you would implement the server-side notification
    // Typically handled by Cloud Functions or your API

    // Sample implementation of what would happen on your server:
    /*
    await FirebaseMessaging.instance.sendToDevice(
      deviceToken,
      RemoteNotificationSettings(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: {
          'type': 'service_request',
          'requestId': requestId,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      ),
    );
    */
  }

  Future<void> _showLocalServiceRequestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print("Showing local notification: $title - $body");

    await setupFlutterNotifications();

    try {
      // Use a unique ID for each notification to prevent overwriting
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _serviceRequestsChannelId,
            'Service Requests',
            channelDescription: 'Notifications for new service requests',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            // These settings help with visibility in background
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            ticker: 'New service request',
            channelShowBadge: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: payload,
      );
      print("Local notification sent successfully with ID: $notificationId");
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  Future<void> _requestPermission() async {
    print("Requesting notification permissions");
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: true, // Request critical alerts on iOS
    );

    print('Permission status: ${settings.authorizationStatus}');

    // On iOS, register for remote notifications (required for background notifications)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      print("Flutter notifications already initialized");
      return;
    }

    print("Setting up Flutter notifications");

    const channel = AndroidNotificationChannel(
      _highImportanceChannelId,
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    const serviceRequestsChannel = AndroidNotificationChannel(
      _serviceRequestsChannelId,
      'Service Requests',
      description: 'Notifications for new service requests',
      importance: Importance.high,
    );

    final flutterLocalNotificationsPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (flutterLocalNotificationsPlugin != null) {
      await flutterLocalNotificationsPlugin.createNotificationChannel(channel);
      await flutterLocalNotificationsPlugin.createNotificationChannel(serviceRequestsChannel);
      print("Notification channels created");
    } else {
      print("Could not resolve Android notification plugin");
    }

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // For iOS, we need notification settings
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle when user taps on notification
        if (details.payload != null) {
          _handleNotificationTap(details.payload!);
        }
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
    print("Flutter notifications initialized successfully");
  }

  void _handleNotificationTap(String payload) {
    // Navigation logic would go here
    print('Notification tapped with payload: $payload');

    // In a real implementation, you would navigate to the appropriate screen
    // For example:
    // NavigationService.navigateTo('/service-request/$payload');
  }

  Future<void> showNotification(RemoteMessage message) async {
    print("Showing notification from FCM message: ${message.messageId}");
    RemoteNotification? notification = message.notification;

    // Generate a unique ID for this notification
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    try {
      // Handle both notification messages and data-only messages
      if (notification != null) {
        // This is a notification message
        await _localNotifications.show(
          notificationId,
          notification.title ?? 'New Notification',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _highImportanceChannelId,
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              fullScreenIntent: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['requestId'] ?? message.data.toString(),
        );
        print("FCM notification displayed with ID: $notificationId");
      } else if (message.data.isNotEmpty) {
        // This is a data-only message
        final title = message.data['title'] ?? 'New Message';
        final body = message.data['body'] ?? 'You have a new message';

        await _localNotifications.show(
          notificationId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _highImportanceChannelId,
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              fullScreenIntent: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['requestId'] ?? message.data.toString(),
        );
        print("FCM data message displayed as notification with ID: $notificationId");
      } else {
        print("Cannot show notification: No notification data or message data");
      }
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  Future<void> _setupMessageHandlers() async {
    print("Setting up FCM message handlers");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print("Received foreground message: ${message.messageId}");
      showNotification(message);
    });

    // Handle when the app is opened from a background message
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("App opened from background message: ${message.messageId}");
      _handleBackgroundMessage(message);
    });

    // Handle when the app is opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("App opened from terminated state with message: ${initialMessage.messageId}");
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print("Handling background message: ${message.data}");

    try {
      // Extract message type and navigate accordingly
      if (message.data['type'] == 'chat') {
        // Handle chat message
        print("Background message is chat type");
        // Navigate to chat screen with the relevant chat ID
        final chatId = message.data['chatId'];
        if (chatId != null) {
          print("Navigating to chat with ID: $chatId");
          // NavigationService.navigateTo('/chat/$chatId');
        }
      } else if (message.data['type'] == 'service_request') {
        // Handle service request
        final requestId = message.data['requestId'];
        if (requestId != null) {
          print("Background message is service_request type with ID: $requestId");
          _handleNotificationTap(requestId);
        }
      } else {
        // Handle generic message
        print("Background message has unknown type, using default handling");
        // Default handling for payload
        final payload = message.data.toString();
        _handleNotificationTap(payload);
      }
    } catch (e) {
      print("Error handling background message: $e");
    }
  }

  void dispose() {
    print("Disposing notification service");
    _requestSubscription?.cancel();
  }

  Future<void> testNotification() async {
    print("Sending test notification");
    await _showLocalServiceRequestNotification(
      title: "Test Notification",
      body: "This is a test service request notification",
      payload: "test-request",
    );
  }
}