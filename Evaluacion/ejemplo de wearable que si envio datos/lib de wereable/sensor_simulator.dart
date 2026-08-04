import 'dart:async';
import 'dart:math';

class SensorSimulator {
  final Random _random = Random();

  int _steps = 0;
  int _heartRate = 72;
  double _calories = 0;
  String _status = 'reposo';

  final _stepsCtrl = StreamController<int>.broadcast();
  final _heartRateCtrl = StreamController<int>.broadcast();
  final _caloriesCtrl = StreamController<int>.broadcast();
  final _statusCtrl = StreamController<String>.broadcast();

  Stream<int> get stepsStream => _stepsCtrl.stream;
  Stream<int> get heartRateStream => _heartRateCtrl.stream;
  Stream<int> get caloriesStream => _caloriesCtrl.stream;
  Stream<String> get statusStream => _statusCtrl.stream;

  int get steps => _steps;
  int get heartRate => _heartRate;
  int get calories => _calories.toInt();
  String get status => _status;

  Timer? _timer;

  void start() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(),
    );
  }

  void _update() {
    if (_random.nextInt(30) == 0) {
      _changeActivity();
    }

    int newSteps = 0;

    switch (_status) {
      case 'caminando':
        newSteps = _random.nextInt(2) + 1;
        break;

      case 'corriendo':
        newSteps = _random.nextInt(4) + 3;
        break;

      default:
        newSteps = 0;
    }

    _steps += newSteps;

    final target = switch (_status) {
      'corriendo' => 145,
      'caminando' => 95,
      _ => 72,
    };

    _heartRate += _random.nextInt(7) - 3;
    _heartRate = _heartRate.clamp(target - 10, target + 10);

    _calories += newSteps * 0.04;

    _stepsCtrl.add(_steps);
    _heartRateCtrl.add(_heartRate);
    _caloriesCtrl.add(_calories.toInt());
    _statusCtrl.add(_status);
  }

  void _changeActivity() {
    const activities = [
      'reposo',
      'caminando',
      'corriendo',
    ];

    _status = activities[_random.nextInt(activities.length)];
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    stop();

    _stepsCtrl.close();
    _heartRateCtrl.close();
    _caloriesCtrl.close();
    _statusCtrl.close();
  }
}