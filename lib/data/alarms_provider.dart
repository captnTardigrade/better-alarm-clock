import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../helpers/db_helper.dart';

enum MathChallengeType {
  Easy,
  Medium,
  Hard,
}

class Alarm {
  String id;
  int hour;
  int minute;
  List<String> repeatingDays;
  bool isRingingToday;
  MathChallengeType mathChallengeType;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatingDays,
    required this.isRingingToday,
    required this.mathChallengeType,
  });

  Map<String, Object> get data {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'repeatingDays': repeatingDays.isEmpty ? '' : repeatingDays.join(' '),
      'isRingingToday': isRingingToday ? 1 : 0,
      'mathChallenge': mathChallengeType.index,
    };
  }
}

class AlarmsProvider with ChangeNotifier {
  List<Alarm> _alarms = [];

  List<Alarm> get alarms {
    return [..._alarms];
  }

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
    notifyListeners();
    await DBHelper.insert('alarms', alarm.data);
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((alarm) => alarm.id == id);
    await DBHelper.delete('alarms', id);
    notifyListeners();
  }

  Future<Alarm> getAlarmById(String alarmId) async {
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
          ),
        )
        .toList();
    notifyListeners();
  }

  static const uuid = Uuid();
}
