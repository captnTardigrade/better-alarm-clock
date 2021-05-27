import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'data/alarms_provider.dart';
import 'screens/add_new_alarm_screen.dart';
import 'screens/edit_alarm_screen.dart';
import 'screens/home_screen.dart';
import 'screens/puzzle_screen.dart';

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
    selectedNotificationPayload = payload;
    selectNotificationSubject.add(payload);
  });
  if (initialRoute == PuzzleScreen.routeName) {
    await FlutterRingtonePlayer.playAlarm(volume: 1);
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => AlarmsProvider(flutterLocalNotificationsPlugin),
      builder: (context, child) => MaterialApp(
        theme: ThemeData(
          primaryColor: Color(0xffBB86FC),
          textTheme: Typography.material2018().white,
          fontFamily: GoogleFonts.roboto().fontFamily,
          canvasColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.black,
            dialHandColor: Colors.purple,
            dialTextColor: Colors.white,
            hourMinuteTextColor: Colors.purple,
            dayPeriodColor: MyColor(),
            dayPeriodTextColor: DayPeriodTextColor(),
            entryModeIconColor: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        initialRoute: initialRoute,
        routes: {
          HomeScreen.routeName: (_) => HomeScreen(
                selectNotificationSubject,
              ),
          PuzzleScreen.routeName: (_) =>
              PuzzleScreen(selectedNotificationPayload),
          AddAlarm.routeName: (_) => AddAlarm(),
          EditAlarm.routeName: (_) => EditAlarm(),
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

class MyColor extends MaterialStateColor {
  const MyColor() : super(_defaultColor);

  static const int _defaultColor = 0xffFFEB3A;
  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.selected)) {
      return const Color(0xffBB86FC);
    }
    return const Color(0xff0000);
  }
}

class DayPeriodTextColor extends MaterialStateColor {
  const DayPeriodTextColor() : super(_defaultColor);

  static const _defaultColor = 0xffffff;

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.selected)) {
      return Colors.black;
    }
    return Colors.white;
  }
}
