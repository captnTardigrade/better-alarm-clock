import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/puzzle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_new_alarm_screen.dart';
import 'data/alarms_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

String? selectedNotificationPayload;
Future<void> main() async {
  // needed if you intend to initialize in the `main` function
  WidgetsFlutterBinding.ensureInitialized();

  await _configureLocalTimeZone();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String initialRoute = HomeScreen.routeName;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload = notificationAppLaunchDetails!.payload;
    initialRoute = PuzzleScreen.routeName;
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    print('Hello');
    print('$initialRoute');
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    selectedNotificationPayload = payload;
    selectNotificationSubject.add(payload);
  });
  // runApp(
  //   MaterialApp(
  //     initialRoute: initialRoute,
  //     routes: <String, WidgetBuilder>{
  //       HomeScreen.routeName: (_) => HomeScreen(),
  //       PuzzleScreen.routeName: (_) => PuzzleScreen()
  //     },
  //   ),
  // );
  if (initialRoute == PuzzleScreen.routeName) {
    FlutterRingtonePlayer.playAlarm(volume: 1);
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => AlarmsProvider(),
      builder: (context, child) => MaterialApp(
        theme: ThemeData(
          textTheme: Typography.material2018().black,
          fontFamily: GoogleFonts.roboto().fontFamily,
          primaryColor: Color(0xffBB86FC),
          appBarTheme: AppBarTheme(
            titleTextStyle: Typography.material2018().white.headline6,
            actionsIconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
        ),
        initialRoute: initialRoute,
        routes: {
          HomeScreen.routeName: (_) =>
              HomeScreen(flutterLocalNotificationsPlugin),
          PuzzleScreen.routeName: (_) => PuzzleScreen(),
          AddAlarm.routeName: (_) => AddAlarm(flutterLocalNotificationsPlugin),
        },
      ),
    ),
  );
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}
