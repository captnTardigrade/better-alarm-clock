import 'package:better_alarm_clock/widgets/appBar.dart';

import 'edit_alarm_screen.dart';

import 'puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../data/alarms_provider.dart';
import 'add_new_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';
  final BehaviorSubject<String?> selectNotificationSubject;
  HomeScreen(this.selectNotificationSubject);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future? _alarmsFuture;

  Future _obtainAlarmsFuture() =>
      Provider.of<AlarmsProvider>(context, listen: false).fetchAndSetAlarms();

  @override
  void initState() {
    super.initState();
    _alarmsFuture = _obtainAlarmsFuture();
    _configureSelectNotificationSubject();
  }

  void _configureSelectNotificationSubject() {
    widget.selectNotificationSubject.stream.listen((String? payload) async {
      await Navigator.pushNamed(
        context,
        PuzzleScreen.routeName,
        arguments: payload,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarmsProvider = Provider.of<AlarmsProvider>(context);
    final alarms = alarmsProvider.alarms;
    return Scaffold(
      appBar: buildAppBar(
        context,
        [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(AddAlarm.routeName),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: FutureBuilder(
          future: _alarmsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                child: CircularProgressIndicator(),
              );
            if (alarms.isNotEmpty) {
              return ListView.builder(
                itemCount: alarms.length,
                itemBuilder: (context, index) => ListTile(
                  onTap: () => Navigator.of(context).pushNamed(
                      EditAlarm.routeName,
                      arguments: alarms[index].id),
                  minVerticalPadding: 10,
                  title: Text(
                    DateFormat('hh:mm a').format(
                      DateTime(
                          1000, 1, 1, alarms[index].hour, alarms[index].minute),
                    ),
                    style: Theme.of(context).textTheme.headline4,
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    alarms[index].repeatingDays.isEmpty ||
                            alarms[index].repeatingDays.first.isEmpty
                        ? 'Not repeating'
                        : alarms[index]
                            .repeatingDays
                            .map((e) => e[0])
                            .join(' '),
                    textAlign: TextAlign.center,
                  ),
                  leading: AlarmToggleButton(alarms[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).errorColor,
                        ),
                        onPressed: () async =>
                            alarmsProvider.deleteAlarm(alarms[index].id),
                      ),
                    ],
                  ),
                ),
              );
            } else
              return Center(
                child: Text(
                  'No alarms added yet!',
                  style: TextStyle(
                      // fontSize: Theme.of(context).textTheme.headline5!.fontSize,
                      ),
                ),
              );
          }),
    );
  }
}

class AlarmToggleButton extends StatefulWidget {
  final Alarm alarm;
  AlarmToggleButton(this.alarm);
  @override
  _AlarmToggleButtonState createState() => _AlarmToggleButtonState();
}

class _AlarmToggleButtonState extends State<AlarmToggleButton> {
  final daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  var _isEnabled;

  @override
  void initState() {
    _isEnabled = widget.alarm.isEnabled;
    super.initState();
  }

  void _toggle() async {
    final alarmsProvider = Provider.of<AlarmsProvider>(context, listen: false);
    setState(() {
      _isEnabled = !_isEnabled;
    });
    final alarm = Alarm(
      id: widget.alarm.id,
      hour: widget.alarm.hour,
      minute: widget.alarm.minute,
      repeatingDays: widget.alarm.repeatingDays,
      isRingingToday: widget.alarm.isRingingToday,
      mathChallengeType: widget.alarm.mathChallengeType,
      isEnabled: _isEnabled,
    );
    alarmsProvider.toggleEnableStatus(alarm);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isEnabled ? Icons.toggle_on : Icons.toggle_off,
        color: _isEnabled ? Theme.of(context).primaryColor : Colors.white,
        size: 40,
      ),
      onPressed: _toggle,
    );
  }
}
