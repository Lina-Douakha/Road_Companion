import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  Future<void> initialize() async {
    print("NotificationService: Initializing...");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


    await _requestPermission();


    await _setupFirestoreListeners();


    await _setupMessageHandlers();


    final token = await _messaging.getToken();
    print('FCM Token: $token');


    await _saveTokenToFirestore(token);


    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

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
        });
        print('FCM token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    } else {
      print('Cannot save FCM token: User not logged in');
    }
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

        if (userData['Role'] == 'towing' || userData['Role'] == 'mechanic') {
          print('Setting up Firestore listener for service provider: ${user.uid}');


          _requestSubscription?.cancel();


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
      print("Document data: ${change.doc.data()}");


      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data != null) {

          final bool alreadyNotified = data['notified'] == true;
          print("Document already notified: $alreadyNotified");

          if (!alreadyNotified) {
            final clientName = data['clientName'] ?? 'A client';
            print("Showing notification for client: $clientName");


            _showLocalServiceRequestNotification(
              title: 'New Service Request',
              body: '$clientName has requested your service',
              payload: change.doc.id,
            );


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

  Future<void> _showLocalServiceRequestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print("Showing local notification: $title - $body");

    await setupFlutterNotifications();

    try {
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'service_requests_channel',
            'Service Requests',
            channelDescription: 'Notifications for new service requests',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      print("Local notification sent successfully");
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
      criticalAlert: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      print("Flutter notifications already initialized");
      return;
    }

    print("Setting up Flutter notifications");

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    const serviceRequestsChannel = AndroidNotificationChannel(
      'service_requests_channel',
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

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
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

    print('Notification tapped with payload: $payload');

  }

  Future<void> showNotification(RemoteMessage message) async {
    print("Showing notification from FCM message");
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
            'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
      print("FCM notification displayed");
    } else {
      print("Could not show FCM notification: notification or android is null");
    }
  }

  Future<void> _setupMessageHandlers() async {
    print("Setting up FCM message handlers");

    //foreground message
    FirebaseMessaging.onMessage.listen((message) {
      print("Received foreground message: ${message.messageId}");
      showNotification(message);
    });

    // background message
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("App opened from background message: ${message.messageId}");
      _handleBackgroundMessage(message);
    });

    // opened app
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("App opened from terminated state with message: ${initialMessage.messageId}");
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print("Handling message: ${message.data}");
    if (message.data['type'] == 'chat') {
      // open chat screen
      print("Message is chat type");
    } else if (message.data['type'] == 'service_request') {
      // Navigate to service request details
      final requestId = message.data['requestId'];
      if (requestId != null) {
        print("Message is service_request type with ID: $requestId");
        _handleNotificationTap(requestId);
      }
    } else {
      print("Message has unknown type");
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