import 'package:better_alarm_clock/data/alarms_provider.dart';
import 'package:better_alarm_clock/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import '../data/math_puzzle_generation.dart';

class PuzzleScreen extends StatefulWidget {
  static const routeName = '/puzzle';

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final _form = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  var puzzle = MathPuzzleGeneration(MathChallengeType.Easy).generatePuzzle();

  var _numTimes = 0;

  void _onFinished() async {
    FocusScope.of(context).requestFocus(_focusNode);
    if (!_form.currentState!.validate()) return;
    setState(() {
      puzzle = MathPuzzleGeneration(MathChallengeType.Easy).generatePuzzle();
    });
    _textController.clear();

    if (_numTimes < 2)
      setState(() {
        _numTimes++;
      });
    else {
      await FlutterRingtonePlayer.stop();
      // Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      Navigator.of(context).pushNamedAndRemoveUntil(
          HomeScreen.routeName, (Route<dynamic> route) => false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // FlutterRingtonePlayer.playAlarm(volume: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Container(
        height: MediaQuery.of(context).size.height * 0.30,
        margin: const EdgeInsets.only(
          top: 150,
          left: 10,
          right: 10,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  '${puzzle['numbers'][0]} + ${puzzle['numbers'][1]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _textController,
                  focusNode: _focusNode,
                  validator: (value) {
                    if (value == null) return 'Entered value is null!';
                    if (value.isEmpty) return 'Enter a value!';
                    try {
                      final result = int.parse(value);
                      if (result != puzzle['answer']) return 'Incorrect';
                    } on FormatException catch (_) {
                      return 'The value entered is not a number!';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) {
                    _onFinished();
                  },
                  autofocus: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
