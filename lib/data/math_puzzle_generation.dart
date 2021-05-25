import 'dart:math';

import 'alarms_provider.dart';

class MathPuzzleGeneration {
  final MathChallengeType mathChallengeType;
  MathPuzzleGeneration(this.mathChallengeType);

  Map<String, dynamic> generatePuzzle() {
    final random = Random(DateTime.now().millisecond);
    final List<int> list = [];
    var answer = 0;
    switch (mathChallengeType) {
      case MathChallengeType.Easy:
        for (var i = 0; i < 2; i++) {
          final number = 1 + random.nextInt(10);
          list.add(number);
          answer += number;
        }
        return {
          'numbers': list,
          'answer': answer,
          'numTimes': 3,
        };
      case MathChallengeType.Medium:
        for (var i = 0; i < 3; i++) {
          final number = 10 + random.nextInt(90);
          list.add(number);
          answer += number;
        }
        return {
          'numbers': list,
          'answer': answer,
          'numTimes': 3,
        };
      case MathChallengeType.Hard:
        for (var i = 0; i < 5; i++) {
          final number = 10 + random.nextInt(90);
          list.add(number);
          answer += number;
        }
        return {
          'numbers': list,
          'answer': answer,
          'numTimes': 5,
        };
    }
  }
}
