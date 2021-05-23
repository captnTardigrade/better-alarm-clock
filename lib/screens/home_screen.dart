import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/alarms_provider.dart';
import 'add_new_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  HomeScreen(this.flutterLocalNotificationsPlugin);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future? _alarmsFuture;

  Future _obtainAlarmsFuture() =>
      Provider.of<AlarmsProvider>(context, listen: false).fetchAndSetAlarms();

  @override
  void initState() {
    _alarmsFuture = _obtainAlarmsFuture();
    super.initState();
  }

  void _addDelayedAlarm() async {
    await widget.flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'scheduled title',
        'scheduled body',
        tz.TZDateTime.now(tz.local).add(
          const Duration(seconds: 5),
        ),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'full screen channel id',
            'full screen channel name',
            'full screen channel description',
            priority: Priority.high,
            importance: Importance.high,
            fullScreenIntent: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  @override
  Widget build(BuildContext context) {
    final alarmsProvider = Provider.of<AlarmsProvider>(context);
    final alarms = alarmsProvider.alarms;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Better alarm clock',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).appBarTheme.actionsIconTheme!.color,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(AddAlarm.routeName),
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
                  minVerticalPadding: 10,
                  title: Text(
                    DateFormat('hh:mm a').format(
                      DateTime(
                          1000, 1, 1, alarms[index].hour, alarms[index].minute),
                    ),
                    style: Theme.of(context).textTheme.headline4,
                    textAlign: TextAlign.center,
                  ),
                  subtitle: alarms[index].repeatingDays.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: alarms[index]
                              .repeatingDays
                              .map(
                                (day) => Text(
                                  '${day[0]} ',
                                ),
                              )
                              .toList())
                      : Center(child: Text('Not Repeating')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {},
                      ),
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
                    fontSize: Theme.of(context).textTheme.headline5!.fontSize,
                  ),
                ),
              );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDelayedAlarm,
        child: Icon(Icons.add),
      ),
    );
  }
}