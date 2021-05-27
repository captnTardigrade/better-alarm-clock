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
  bool isEnabled;
  MathChallengeType mathChallengeType;
  int numPuzzles;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatingDays,
    required this.mathChallengeType,
    required this.isEnabled,
    required this.numPuzzles,
  });

  Map<String, Object> get data {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'repeatingDays': repeatingDays.isEmpty ? '' : repeatingDays.join(' '),
      'mathChallenge': mathChallengeType.index,
      'isEnabled': isEnabled ? 1 : 0,
      'numPuzzles': numPuzzles,
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

  void addAlarm(Alarm alarm) {
    _alarms.add(alarm);
    enableAlarm(alarm);
    notifyListeners();
    DBHelper.insert('alarms', alarm.data);
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
            mathChallengeType: getMathChallengeType(alarm['mathChallenge']),
            isEnabled: alarm['isEnabled'] == 0 ? false : true,
            numPuzzles: alarm['numPuzzles'],
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
            mathChallengeType: getMathChallengeType(alarm['mathChallenge']),
            isEnabled: alarm['isEnabled'] == 0 ? false : true,
            numPuzzles: alarm['numPuzzles'],
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
      TimeOfDay time,
      String numRingTimes) async {
    if (repeatingDays.isEmpty || repeatingDays.first.isEmpty) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmId,
        'THE ALARM\'S RINGING!',
        'WAKE UP',
        _nextInstanceOfTime(time),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            '42',
            'Better alarm clock',
            'Made with flutter',
            priority: Priority.high,
            importance: Importance.high,
            fullScreenIntent: true,
            playSound: false,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: mathChallengeType + ' ' + numRingTimes,
      );
    } else if (repeatingDays.length == 7) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmId,
        'THE ALARM\'S RINGING',
        'WAKE UP',
        _nextInstanceOfTime(time),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            '42',
            'Better alarm clock',
            'Made with flutter',
            playSound: false,
            fullScreenIntent: true,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        payload: mathChallengeType + ' ' + numRingTimes,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else
      for (var day in repeatingDays) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          alarmId,
          'THE ALARM\'S RINGING!',
          'WAKE UP',
          _nextInstanceOfWeekday(time, daysOfWeek.indexOf(day) + 1),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              '42',
              'Better alarm clock',
              'Made with flutter',
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
          payload: mathChallengeType + ' ' + numRingTimes,
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
      alarm.numPuzzles.toString(),
    );
  }

  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
