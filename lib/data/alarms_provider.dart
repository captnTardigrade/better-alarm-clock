import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../helpers/db_helper.dart';

enum MathChallengeType {
  Easy,
  Medium,
  Hard,
}

class Alarm {
  int id;
  int hour;
  int minute;
  List<String> repeatingDays;
  bool isRingingToday;
  bool isEnabled;
  MathChallengeType mathChallengeType;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatingDays,
    required this.isRingingToday,
    required this.mathChallengeType,
    required this.isEnabled,
  });

  Map<String, Object> get data {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'repeatingDays': repeatingDays.isEmpty ? '' : repeatingDays.join(' '),
      'isRingingToday': isRingingToday ? 1 : 0,
      'mathChallenge': mathChallengeType.index,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }
}

class AlarmsProvider with ChangeNotifier {
  final daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  List<Alarm> _alarms = [];

  List<Alarm> get alarms {
    return [..._alarms];
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  AlarmsProvider(this.flutterLocalNotificationsPlugin);

  static MathChallengeType getMathChallengeType(int i) {
    switch (i) {
      case 1:
        return MathChallengeType.Medium;
      case 2:
        return MathChallengeType.Hard;
      default:
        return MathChallengeType.Easy;
    }
  }

  void addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    enableAlarm(alarm);
    notifyListeners();
    await DBHelper.insert('alarms', alarm.data);
  }

  Future<void> deleteAlarm(int id) async {
    _alarms.removeWhere((alarm) => alarm.id == id);
    await cancelAlarm(id);
    await DBHelper.delete('alarms', id);
    notifyListeners();
  }

  Future<Alarm> getAlarmById(int alarmId) async {
    final dataList = await DBHelper.getData('alarms');
    final alarms = dataList
        .map(
          (alarm) => Alarm(
            id: alarm['id'],
            hour: alarm['hour'],
            minute: alarm['minute'],
            repeatingDays: alarm['repeatingDays'].split(r' '),
            isRingingToday: alarm['isRingingToday'] == 0 ? false : true,
            mathChallengeType: getMathChallengeType(alarm['mathChallenge']),
            isEnabled: alarm['isEnabled'] == 0 ? false : true,
          ),
        )
        .toList();
    return alarms.firstWhere((element) => element.id == alarmId);
  }

  Future<void> fetchAndSetAlarms() async {
    final dataList = await DBHelper.getData('alarms');
    _alarms = dataList
        .map(
          (alarm) => Alarm(
            id: alarm['id'],
            hour: alarm['hour'],
            minute: alarm['minute'],
            repeatingDays: alarm['repeatingDays'].split(r' '),
            isRingingToday: alarm['isRingingToday'] == 0 ? false : true,
            mathChallengeType: getMathChallengeType(alarm['mathChallenge']),
            isEnabled: alarm['isEnabled'] == 0 ? false : true,
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm newAlarm) async {
    await DBHelper.update('alarms', newAlarm);
    final index = _alarms.indexWhere((alarm) => alarm.id == newAlarm.id);
    _alarms.removeAt(index);
    _alarms.insert(index, newAlarm);
    await cancelAlarm(newAlarm.id);
    enableAlarm(newAlarm);
    notifyListeners();
  }

  Future<void> toggleEnableStatus(Alarm newAlarm) async {
    await DBHelper.update('alarms', newAlarm);
    final index = _alarms.indexWhere((alarm) => alarm.id == newAlarm.id);
    _alarms.removeAt(index);
    _alarms.insert(index, newAlarm);
    if (newAlarm.isEnabled)
      enableAlarm(newAlarm);
    else
      cancelAlarm(newAlarm.id);
    notifyListeners();
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekday(TimeOfDay time, int weekday) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _showFullScreenNotification(
      int alarmId,
      String mathChallengeType,
      List<String> repeatingDays,
      TimeOfDay time) async {
    if (repeatingDays.isEmpty || repeatingDays.first.isEmpty) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmId,
        'scheduled title',
        'scheduled body',
        _nextInstanceOfTime(time),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'full screen channel id',
            'full screen channel name',
            'full screen channel description',
            priority: Priority.high,
            importance: Importance.high,
            fullScreenIntent: true,
            playSound: false,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: mathChallengeType,
      );
    } else
      for (var day in repeatingDays) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          alarmId,
          'weekly scheduled notification title',
          'weekly scheduled notification body',
          _nextInstanceOfWeekday(time, daysOfWeek.indexOf(day)),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'weekly notification channel id',
              'weekly notification channel name',
              'weekly notificationdescription',
              fullScreenIntent: true,
              playSound: false,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: mathChallengeType,
        );
      }
  }

  void enableAlarm(Alarm alarm) {
    _showFullScreenNotification(
      alarm.id,
      alarm.mathChallengeType.index.toString(),
      alarm.repeatingDays,
      TimeOfDay(
        hour: alarm.hour,
        minute: alarm.minute,
      ),
    );
  }

  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
