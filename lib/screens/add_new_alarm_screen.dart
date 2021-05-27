import 'dart:math';

import 'package:better_alarm_clock/widgets/appBar.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:provider/provider.dart';

import '../data/alarms_provider.dart';

class AddAlarm extends StatefulWidget {
  static const routeName = '/add-alarm';
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
  bool _isRingingToday = true;
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
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(
      () {
        _timeOfDay = time;
      },
    );
  }

  void _saveAlarm(TimeOfDay? time) {
    if (time == null) throw 'Time not set error';
    final newAlarm = Alarm(
      id: Random(DateTime.now().millisecondsSinceEpoch).nextInt(
        pow(2, 31).toInt(),
      ),
      hour: time.hour,
      minute: time.minute,
      repeatingDays: daysOfWeek
          .where((element) => _repeatingDays[daysOfWeek.indexOf(element)])
          .toList(),
      isRingingToday: _isRingingToday,
      mathChallengeType: _mathChallengeType,
      isEnabled: true,
    );
    Provider.of<AlarmsProvider>(context, listen: false).addAlarm(newAlarm);
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
      appBar: buildAppBar(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_timeOfDay != null)
            Container(
              height: 100,
              width: double.infinity,
              child: Center(
                child: Text(
                  _timeOfDay!.format(context),
                  style: Theme.of(context)
                      .textTheme
                      .headline2!
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
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
                            ? Border.all(width: 3.5, color: Colors.red)
                            : null,
                      ),
                      margin: const EdgeInsets.all(5),
                      child: CircleAvatar(
                        backgroundColor: Color(0xff03DAC5),
                        child: Center(
                          child: Text(
                            day[0],
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        radius: 15,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          Text(
            'Math puzzle level',
            style: TextStyle(
              color: Colors.black,
              fontSize: Theme.of(context).textTheme.bodyText1!.fontSize,
            ),
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
            selectedColor: Color(0xff03DAC5),
            unselectedTextStyle:
                TextStyle(color: Theme.of(context).primaryColor),
            selectedButtons: ['EASY'],
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
                        backgroundColor: Colors.black,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Okay',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                        content: Text(
                          'Please choose a time!',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
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
    );
  }
}
