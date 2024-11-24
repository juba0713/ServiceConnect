import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/chat/user_chat_list_screen.dart';
import 'constant.dart';

//region Handle Background Firebase Message
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp().then((value) {}).catchError((e) {});
}
//endregion

Future<void> initFirebaseMessaging() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.instance.setAutoInitEnabled(true).then((value) {
    FirebaseMessaging.onMessage.listen((message) async {
      if (message.notification != null && message.notification!.title.validate().isNotEmpty && message.notification!.body.validate().isNotEmpty) {
        log('NOTIFICATIONDATA: ${message.data}');
        showNotification(currentTimeStamp(), message.notification!.title.validate(), message.notification!.body.validate(), message);
      }
    });

    //When the app is in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      //Handle onClick Notification
      handleNotificationClick(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      //Handle onClick Notification
      if (message != null) {
        handleNotificationClick(message);
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  });

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
}

Future<void> subscribeToFirebaseTopic() async {
  if (appStore.isLoggedIn) {
    await initFirebaseMessaging();

    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        await 3.seconds.delay;
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      }

      if (apnsToken != null) {
        await FirebaseMessaging.instance.subscribeToTopic('user_${appStore.userId}');
        final topicTag = isUserTypeHandyman ? HANDYMAN_APP_TAG : PROVIDER_APP_TAG;
        await FirebaseMessaging.instance.subscribeToTopic(topicTag).whenComplete(() {
          log('topic-----Subscribed---->------> $topicTag');
        });
      }

      log('Apn Token=========${apnsToken}');
    } else {
      await FirebaseMessaging.instance.subscribeToTopic('user_${appStore.userId}');
      if (isUserTypeHandyman) {
        await FirebaseMessaging.instance.subscribeToTopic(HANDYMAN_APP_TAG).whenComplete(() {
          log('topic-----Subscribed---->------> $HANDYMAN_APP_TAG');
        });
      } else if (isUserTypeProvider) {
        await FirebaseMessaging.instance.subscribeToTopic(PROVIDER_APP_TAG).whenComplete(() {
          log('topic-----Subscribed---->------> $PROVIDER_APP_TAG');
        });
      }
    }
    log("topic---------> user_${appStore.userId}");
  }
}

Future<void> unsubscribeFirebaseTopic(int userId) async {
  await FirebaseMessaging.instance.unsubscribeFromTopic('user_$userId').whenComplete(() {
    log("topic-----unSubscribed----> user_$userId");
  });
  if (isUserTypeProvider) {
    FirebaseMessaging.instance.unsubscribeFromTopic(PROVIDER_APP_TAG).whenComplete(() {
        log('topic-----unSubscribed---->------> $PROVIDER_APP_TAG');
      });
  }
  if (isUserTypeHandyman) {
    FirebaseMessaging.instance.unsubscribeFromTopic(HANDYMAN_APP_TAG).whenComplete(() {
        log('topic-----unSubscribed---->------> $HANDYMAN_APP_TAG');
      });
  }
}

void handleNotificationClick(RemoteMessage message) {
  if (message.data.containsKey('is_chat')) {
    if (message.data.isNotEmpty) {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => ChatListScreen()));
      // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => UserChatScreen(receiverUser: UserData.fromJson(message.data))));
    }
  } else if (message.data.containsKey('id')) {
    String? notId = message.data["id"].toString();
    if (notId.validate().isNotEmpty) {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => BookingDetailScreen(bookingId: notId.toString().toInt())));
    }
  }
}

void showNotification(int id, String title, String message, RemoteMessage remoteMessage) async {
  log(title);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  //code for background notification channel
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'notification',
    'Notification',
    importance: Importance.high,
    enableLights: true,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_stat_ic_notification');
  var iOS = const DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  var macOS = iOS;
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: iOS, macOS: macOS);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      handleNotificationClick(remoteMessage);
    },
  );

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'notification',
    'Notification',
    importance: Importance.high,
    visibility: NotificationVisibility.public,
    autoCancel: true,
    //color: primaryColor,
    playSound: true,
    priority: Priority.high,
    icon: '@drawable/ic_stat_ic_notification',
  );

  var darwinPlatformChannelSpecifics = const DarwinNotificationDetails();

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: darwinPlatformChannelSpecifics,
    macOS: darwinPlatformChannelSpecifics,
  );

  flutterLocalNotificationsPlugin.show(id, title, message, platformChannelSpecifics);
}
