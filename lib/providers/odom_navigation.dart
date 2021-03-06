import 'package:flutter/foundation.dart';
import 'package:robot_gui/providers/ros_client.dart';
import 'package:roslib/actionlib/action_goal.dart';

import '../models/odompoint.dart';

enum NavigationDirection {
  ahead,
  back,
  left,
  right,
  unkown,
}

enum NavigationMode {
  go,
  goReturnRecursive,
  goReturnCircular,
}

class OdomNavigationProvider with ChangeNotifier {
  late ROSClient _ros;
  NavigationMode _mode = NavigationMode.go;
  bool _initiated = false;
  OdomNavigationProvider();
  factory OdomNavigationProvider.update(
      ROSClient ros, OdomNavigationProvider obj) {
    obj._ros = ros;
    return obj;
  }

  Future<void> initiate() async {
    if (!_initiated) {
      await _ros.odomAction.connect();
      _initiated = true;
    }
  }

  bool _isNavigating = false;

  bool get isNavigating => _isNavigating;
  set isNavigating(bool v) {
    // if (_currentTarget == null) {
    //   return;
    // }
    _isNavigating = v;
    notifyListeners();
  }

  List<bool> get navigationModeMask {
    final x = [false, false, false];
    x[_mode.index] = true;
    return x;
  }

  NavigationMode get mode => _mode;
  set mode(NavigationMode v) {
    _mode = v;
    notifyListeners();
  }

  int? _currentTarget;

  OdomPoint? get currentTarget {
    if (_currentTarget != null) return _wayPoints[_currentTarget!];
    return null;
  }

  void setCurrentTarget(int? _p) {
    _currentTarget = _p;
    notifyListeners();
  }

  final List<OdomPoint> _wayPoints = [];

  List<OdomPoint> get wayPoints => _wayPoints;

  void deleteWayPoint(OdomPoint p) {
    _wayPoints.remove(p);
    notifyListeners();
  }

  void addWayPoint(OdomPoint p, {int? index}) {
    if (!_wayPoints.contains(p)) {
      if (index == null) {
        _wayPoints.add(p);
      } else {
        _wayPoints.insert(index, p);
      }
    }
    notifyListeners();
  }

  void replaceWayPoint(int oldIndex, int newIndex) {
    _wayPoints.insert(newIndex, _wayPoints.removeAt(oldIndex));
    notifyListeners();
  }

  void clearPath() {
    _wayPoints.clear();
    notifyListeners();
  }

  void swapPoints() {
    if (_swap.length == 2) {
      final temp = _wayPoints[_swap[0]]
        ..provider.willSwap = false
        ..provider.hover = true;
      _wayPoints[_swap[0]] = _wayPoints[_swap[1]]
        ..provider.willSwap = false
        ..provider.hover = false;
      _wayPoints[_swap[1]] = temp;
      notifyListeners();
    }
  }

  void changeIndex(int i) {
    if (i < _wayPoints.length) {
      final temp = _wayPoints[i];
      _wayPoints.remove(temp);
      _wayPoints.insert(i, temp);
    }
  }

  Stream<NavigationDirection> get direction => _ros.relativePose.map(
        (event) {
          final data = (event as Map)['yaw'] as double;
          if (data - 0.0 < 0.0001) {
            return NavigationDirection.back;
          }
          return NavigationDirection.unkown;
        },
      );

  bool _editablePath = false;
  bool get editablePath => _editablePath;
  set editablePath(bool v) {
    _editablePath = v;
    notifyListeners();
  }

  bool _editableWayPointList = false;
  bool get editableWayPointList => _editableWayPointList;
  set editableWayPointList(bool v) {
    _editableWayPointList = v;
    notifyListeners();
  }

  final List<int> _swap = [];

  void addToSwapList(int w) {
    if (_swap.length < 2) {
      _swap.add(w);
      if (_swap.length == 2) {
        swapPoints();
        clearSwap();
      }
    } else {
      clearSwap();
    }
  }

  void clearSwap() {
    _swap.clear();
  }

  Future<void> start() async {
    // print({
    //   'targetPoses': _wayPoints.map(
    //     (e) => {
    //       'position': {
    //         'x': e.x,
    //         'y': e.y,
    //         'z': 0,
    //       },
    //       'orientation': {
    //         'x': 0,
    //         'y': 0,
    //         'z': 0,
    //         'w': 1,
    //       },
    //       'repeated': true,
    //       'recursive': true,
    //       'returnHome': true
    //     },
    //   )
    // });
    _ros.isAutonomous = true;
    if (_ros.isAutonomous) {
      _ros.odomAction.setGoal(
        goal: {
          'targetPoses': _wayPoints
              .map(
                (e) => {
                  'position': {
                    'x': e.x,
                    'y': e.y,
                    'z': 0,
                  },
                  'orientation': {
                    'x': 0,
                    'y': 0,
                    'z': 0,
                    'w': 1,
                  },
                },
              )
              .toList(),
          'repeated': {'data': false},
          'recursive': {'data': false},
          'returnHome': {'data': false},
        },
      );
    }
    isNavigating = true;
  }

  Future<void> cancel() async {
    _ros.odomAction.cancel();
    isNavigating = false;
  }
}
