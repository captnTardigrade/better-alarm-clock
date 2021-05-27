import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:provider/provider.dart';

import '../data/alarms_provider.dart';

class EditAlarm extends StatefulWidget {
  static const routeName = 'edit-screen';
  @override
  _EditAlarmState createState() => _EditAlarmState();
}

class _EditAlarmState extends State<EditAlarm> {
  bool _isInit = true;
  Future? _alarmsFuture;

  TimeOfDay? _timeOfDay;
  final daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  var _repeatingDays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];
  MathChallengeType? _mathChallengeType;

  @override
  void didChangeDependencies() {
    final alarmId = ModalRoute.of(context)!.settings.arguments as int;
    _alarmsFuture = Provider.of<AlarmsProvider>(context).getAlarmById(alarmId);
    super.didChangeDependencies();
  }

  Future<TimeOfDay> _editTime(
      BuildContext context, TimeOfDay initialTime) async {
    final time =
        await showTimePicker(context: context, initialTime: initialTime);
    return time ?? initialTime;
  }

  void _toggleSelection(int index) {
    setState(() {
      _repeatingDays[index] = !_repeatingDays[index];
    });
  }

  void _saveAlarm(Alarm alarm) {
    final alarmsProvider = Provider.of<AlarmsProvider>(
      context,
      listen: false,
    );
    alarmsProvider.updateAlarm(
      Alarm(
        id: alarm.id,
        hour: _timeOfDay!.hour,
        minute: _timeOfDay!.minute,
        isEnabled: alarm.isEnabled,
        isRingingToday: alarm.isEnabled,
        mathChallengeType: _mathChallengeType!,
        repeatingDays: daysOfWeek
            .where((element) => _repeatingDays[daysOfWeek.indexOf(element)])
            .toList(),
      ),
    );
    Navigator.of(context).pop();
  }

  String get _selectedChallenge {
    switch (_mathChallengeType) {
      case MathChallengeType.Easy:
        return 'EASY';
      case MathChallengeType.Medium:
        return 'MEDIUM';
      case MathChallengeType.Hard:
        return 'HARD';
      default:
        return 'EASY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Better alarm clock'),
      ),
      body: FutureBuilder(
        future: _alarmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );

          final alarm = snapshot.data as Alarm;
          if (_isInit) {
            if (alarm.repeatingDays.isNotEmpty &&
                alarm.repeatingDays.first.isNotEmpty)
              for (var day in alarm.repeatingDays) {
                _repeatingDays[daysOfWeek.indexOf(day)] = true;
              }
            _mathChallengeType = alarm.mathChallengeType;
            _isInit = false;
          }
          final initialTime = TimeOfDay(hour: alarm.hour, minute: alarm.minute);
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      _timeOfDay?.format(context) ??
                          initialTime.format(context),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize:
                            Theme.of(context).textTheme.headline2!.fontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _timeOfDay = await _editTime(context, initialTime);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).primaryColor,
                    textStyle: Theme.of(context).textTheme.headline5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('EDIT TIME'),
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
                  onSelected: (i, _) => _mathChallengeType =
                      AlarmsProvider.getMathChallengeType(i),
                  buttons: ['EASY', 'MEDIUM', 'HARD'],
                  borderRadius: BorderRadius.circular(10),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                  ),
                  unselectedTextStyle:
                      TextStyle(color: Theme.of(context).primaryColor),
                  selectedButtons: [_selectedChallenge],
                ),
                SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _saveAlarm(alarm);
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
        },
      ),
    );
  }
}
