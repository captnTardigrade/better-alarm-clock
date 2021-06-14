import '../data/alarms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import '../data/math_puzzle_generation.dart';

class PuzzleScreen extends StatefulWidget {
  static const routeName = '/puzzle';

  final String? payload;

  PuzzleScreen(this.payload);

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  String? _payload;
  bool _isInit = true;
  var numRingTimes = 0;

  @override
  void initState() {
    super.initState();
    if (_isInit) {
      FlutterRingtonePlayer.playAlarm(volume: 1);
      final data = widget.payload!.split(' ');
      numRingTimes = int.parse(data[1]) - 1;
      _payload = data[0];
      puzzle = MathPuzzleGeneration(
        AlarmsProvider.getMathChallengeType(
          int.parse(_payload!),
        ),
      ).generatePuzzle();
    }
    _isInit = false;
  }

  final _form = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  late Map<String, dynamic> puzzle;

  var _numTimes = 0;

  void _onFinished() async {
    FocusScope.of(context).requestFocus(_focusNode);
    if (!_form.currentState!.validate()) return;
    if (_numTimes < numRingTimes) {
      setState(() {
        puzzle = MathPuzzleGeneration(
          AlarmsProvider.getMathChallengeType(
            int.parse(_payload!),
          ),
        ).generatePuzzle();
        _numTimes++;
      });
      _textController.clear();
    } else {
      await FlutterRingtonePlayer.stop();
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleText = (puzzle['numbers'] as List<int>).join(' + ');
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.35,
            margin: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Form(
              key: _form,
              child: ListView(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(10),
                            right: Radius.circular(10),
                          ),
                          color: Colors.yellow,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: _numTimes / (numRingTimes + 1),
                        ),
                        height: 15,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 15,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    puzzleText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline5!.copyWith(
                          color: Colors.black,
                        ),
                  ),
                  TextFormField(
                    style: Theme.of(context).textTheme.headline5!.copyWith(
                          color: Colors.red,
                        ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color(0xff2296F3),
                        ),
                      ),
                    ),
                    cursorColor: Colors.red,
                    cursorHeight: 25,
                    keyboardType: TextInputType.number,
                    controller: _textController,
                    focusNode: _focusNode,
                    validator: (value) {
                      if (value == null) return 'Entered value is null!';
                      if (value.isEmpty) return 'Enter a value!';
                      try {
                        final result = int.parse(value);
                        if (result != puzzle['answer']) {
                          _textController.clear();
                          return 'Incorrect';
                        }
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
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    '${_numTimes + 1}/${numRingTimes + 1}',
                    style: Theme.of(context).textTheme.headline6!.copyWith(
                          color: Colors.black,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
