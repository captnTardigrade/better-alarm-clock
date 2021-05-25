import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import 'package:group_button/group_button.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

import '../data/alarms_provider.dart';

void callback() async {
  FlutterRingtonePlayer.playAlarm(
    looping: false,
    asAlarm: true,
    volume: 1,
  );

  await Future.delayed(Duration(seconds: 20), () {
    FlutterRingtonePlayer.stop();
  });
}

class AddAlarm extends StatefulWidget {
  static const routeName = '/add-alarm';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  AddAlarm(this.flutterLocalNotificationsPlugin);

  @override
  _AddAlarmState createState() => _AddAlarmState();
}

class _AddAlarmState extends State<AddAlarm> {
  final daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  TimeOfDay? _timeOfDay;
  bool _isRingingToday = false;
  MathChallengeType _mathChallengeType = MathChallengeType.Easy;
  var _repeatingDays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  Future<void> setTime(BuildContext context) async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(
      () {
        _timeOfDay = time;
      },
    );
  }

  Future<void> _showFullScreenNotification(
      Duration delay, String mathChallengeType) async {
    await widget.flutterLocalNotificationsPlugin.zonedSchedule(
      Random().nextInt(pow(2, 31).toInt()),
      'scheduled title',
      'scheduled body',
      tz.TZDateTime.now(tz.local).add(delay),
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
  }

  void _saveAlarm(TimeOfDay? time) {
    if (time == null) throw 'Time not set error';
    final newAlarm = Alarm(
      id: AlarmsProvider.uuid.v1(),
      hour: time.hour,
      minute: time.minute,
      repeatingDays: daysOfWeek
          .where((element) => _repeatingDays[daysOfWeek.indexOf(element)])
          .toList(),
      isRingingToday: _isRingingToday,
      mathChallengeType: _mathChallengeType,
    );
    Provider.of<AlarmsProvider>(context, listen: false).addAlarm(newAlarm);
    final delay = Duration(
      hours: newAlarm.hour - TimeOfDay.now().hour,
      minutes: newAlarm.minute - TimeOfDay.now().minute,
    );
    _showFullScreenNotification(
      delay,
      newAlarm.mathChallengeType.index.toString(),
    );
    print(newAlarm.mathChallengeType);
    Navigator.of(context).pop();
  }

  void _toggleSelection(int index) {
    setState(() {
      _repeatingDays[index] = !_repeatingDays[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Better alarm clock',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).appBarTheme.actionsIconTheme!.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_timeOfDay != null)
              Container(
                height: 100,
                width: double.infinity,
                child: Center(
                  child: Text(
                    _timeOfDay!.format(context),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: Theme.of(context).textTheme.headline2!.fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (_timeOfDay == null)
              SizedBox(
                height: 20,
              ),
            ElevatedButton(
              onPressed: () => setTime(context),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).primaryColor,
                textStyle: Theme.of(context).textTheme.headline5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'SET TIME',
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: daysOfWeek
                  .map(
                    (day) => InkWell(
                      onTap: () {
                        _toggleSelection(daysOfWeek.indexOf(day));
                      },
                      customBorder: CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: _repeatingDays[daysOfWeek.indexOf(day)]
                              ? Border.all(width: 4, color: Colors.green)
                              : null,
                        ),
                        margin: const EdgeInsets.all(5),
                        child: CircleAvatar(
                          child: Center(
                            child: Text(day[0]),
                          ),
                          radius: 15,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(
              height: 40,
            ),
            Text(
              'Math puzzle level',
              style: TextStyle(
                color: Colors.black,
                fontSize: Theme.of(context).textTheme.bodyText1!.fontSize,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            GroupButton(
              isRadio: true,
              spacing: 10,
              onSelected: (i, _) =>
                  _mathChallengeType = AlarmsProvider.getMathChallengeType(i),
              buttons: ['EASY', 'MEDIUM', 'HARD'],
              borderRadius: BorderRadius.circular(10),
              selectedTextStyle: TextStyle(
                color: Colors.white,
              ),
              unselectedTextStyle:
                  TextStyle(color: Theme.of(context).primaryColor),
              selectedButtons: ['EASY'],
            ),
            SizedBox(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    try {
                      _saveAlarm(_timeOfDay);
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Okay'),
                            ),
                          ],
                          content: Text('Please choose a time!'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'SAVE',
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).primaryColor,
                    textStyle: Theme.of(context).textTheme.headline6,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
