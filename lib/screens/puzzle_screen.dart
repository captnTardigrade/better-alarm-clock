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
    if (_isInit) FlutterRingtonePlayer.playAlarm(volume: 1);
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
    final payload = ModalRoute.of(context)?.settings.arguments as String?;
    _payload = payload ?? 'Failed';
    puzzle = MathPuzzleGeneration(
      AlarmsProvider.getMathChallengeType(
        int.parse(_payload!),
      ),
    ).generatePuzzle();
    numRingTimes = puzzle['numTimes'];
    final puzzleText = (puzzle['numbers'] as List<int>).join(' + ');
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.blue,
        body: Container(
          height: MediaQuery.of(context).size.height * 0.25,
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
                    puzzleText,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
