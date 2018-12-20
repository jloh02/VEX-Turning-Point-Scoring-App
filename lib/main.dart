import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:core';

void main() {
  SystemChrome.setPreferredOrientations([
    //Set orientation to always portrait
    DeviceOrientation.portraitUp,
    //TODO Change settings for iOS refer to: https://stackoverflow.com/questions/47393690/flutter-how-to-avoid-change-orientation
  ]).then((_) => runApp(MyApp()));
}

Color allianceBlue = Colors.blue[800];

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '8059 Blank. VRC',
      theme: ThemeData(),
      home: CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  @override
  CalculatorPageState createState() {
    return CalculatorPageState();
  }
}

List<int> _flagStatus = List();

class Score {
  int lowCap, highCap, lowFlag, highFlag, alliancePark, centerPark;
  bool auton;

  Score() {
    lowCap = 0;
    highCap = 0;
    lowFlag = 0;
    highFlag = 0;
    alliancePark = 0;
    centerPark = 0;
    auton = false;
  }

  int getScore() {
    int autonScore = auton ? 4 : 0;
    return (lowCap + lowFlag) * 1 +
        (highCap + highFlag) * 2 +
        alliancePark * 3 +
        centerPark * 6 +
        autonScore;
  }

  void clear() {
    lowCap = 0;
    highCap = 0;
    lowFlag = 0;
    highFlag = 0;
    alliancePark = 0;
    centerPark = 0;
    auton = false;
    _flagStatus.clear();
    for (int i = 0; i < 9; i++) _flagStatus.add(0);
  }
}

Score _redScore = Score(), _blueScore = Score();
bool _panning = false;
double _boxHeight;

class CapLevel extends StatelessWidget {
  int _numScored, _max;
  bool _red;

  CapLevel(this._max, this._numScored, this._red);

  @override
  Widget build(BuildContext context) {
    List<Widget> _boxes = List();
    for (int i = 0; i < _max; i++) {
      Color _c;
      if (i >= _numScored)
        _c = Colors.white;
      else {
        if (_red)
          _c = Colors.red;
        else
          _c = allianceBlue;
      }
      _boxes.insert(
        0,
        GestureDetector(
          onTapDown: (TapDownDetails d) {
            if (!_panning) {
              if (_red) {
                if (_max == 8)
                  _redScore.lowCap = i + 1;
                else
                  _redScore.highCap = i + 1;
              } else {
                if (_max == 8)
                  _blueScore.lowCap = i + 1;
                else
                  _blueScore.highCap = i + 1;
              }
            }
          },
          child: Container(
            width: 50.0,
            height: _boxHeight,
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(
                color: Colors.black,
                width: 0.5,
              ),
            ),
          ),
        ),
      );
    }
    return Column(children: _boxes);
  }
}

class CalculatorPageState extends State<CalculatorPage> {
  Stopwatch _s = Stopwatch();
  bool _stopwatchStarted = false;
  bool _matchType = true;
  Duration _lastTime = Duration(seconds: 0);
  int _autonWin = 0;
  static const double _autonButtonWidth = 60.0;
  List<double> _initCaps = List();
  List<int> _initVal = List();
  SharedPreferences sf;
  TextEditingController _skills = TextEditingController(),
      _match = TextEditingController();
  bool _sfInited = false;

  Future<Null> _initSF() async {
    sf = await SharedPreferences.getInstance();
    _skills.text = (sf.getInt('skills_warning') ?? 15).toString();
    _match.text = (sf.getInt('match_warning') ?? 15).toString();
    _sfInited = true;
  }

  Future<Null> _saveTimes() async {
    if (_sfInited) {
      var s = int.tryParse(_skills.text);
      if (s != null) await sf.setInt('skills_warning', s);
      var m = int.tryParse(_match.text);
      if (m != null) await sf.setInt('match_warning', m);
    }
  }

  @override
  void initState() {
    _initSF();
    for (int i = 0; i < 9; i++) _flagStatus.add(0);
    for (int i = 0; i < 4; i++) _initCaps.add(0);
    _initVal.add(_redScore.highCap);
    _initVal.add(_redScore.lowCap);
    _initVal.add(_blueScore.highCap);
    _initVal.add(_blueScore.lowCap);
    super.initState();
  }

  Future<Null> _vibrateIfWarn(int _d) async {
    //debugPrint(_d.toString());
    if (await Vibration.hasVibrator()) {
      //debugPrint('has vibrator');
      if (_sfInited) {
        //debugPrint('inited');
        if (_matchType) {
          //debugPrint(_d.toString());
          //debugPrint(sf.getInt('match_warning') ?? 15.toString());
          if (_d.round() == (sf.getInt('match_warning') ?? 15).round()) {
            //debugPrint('Vibrating');
            Vibration.vibrate(duration: 500);
          }
        } else {
          //debugPrint('d:' + _d.toString());
          //debugPrint('sf:' + (sf.getInt('match_warning') ?? 15).toString());
          if (_d.round() == (sf.getInt('skills_warning') ?? 15).round()) {
            //debugPrint('Vibrating');
            Vibration.vibrate(duration: 500);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_redScore.highCap < 0)
      _redScore.highCap = 0;
    else if (_redScore.highCap > 6) _redScore.highCap = 6;
    if (_blueScore.highCap < 0)
      _blueScore.highCap = 0;
    else if (_blueScore.highCap > 6) _blueScore.highCap = 6;
    if (_redScore.lowCap < 0)
      _redScore.lowCap = 0;
    else if (_redScore.lowCap > 8) _redScore.lowCap = 8;
    if (_blueScore.lowCap < 0)
      _blueScore.lowCap = 0;
    else if (_blueScore.lowCap > 8) _blueScore.lowCap = 8;

    double _flagWidth = (MediaQuery.of(context).size.width - 130.0) / 3;
    _boxHeight = (MediaQuery.of(context).size.height - 230.0) / 14;
    Duration _d = Duration(seconds: 0);
    if (_s.isRunning) {
      if (_matchType)
        _d = Duration(minutes: 1, seconds: 45) - _s.elapsed;
      else
        _d = Duration(minutes: 1) - _s.elapsed;

      if (_d.inSeconds < 0) _d = Duration(seconds: 0);
    } else if (!_stopwatchStarted) {
      if (_matchType)
        _d = Duration(minutes: 1, seconds: 45) - _lastTime;
      else
        _d = Duration(minutes: 1) - _lastTime;
    }

    _vibrateIfWarn(_d.inSeconds);

    List<Widget> _flagGrid = List();
    for (int i = 0; i < 3; i++) {
      List<Widget> _flagRow = List();
      for (int j = 0; j < 3; j++) {
        if (j > 0) _flagRow.add(Container(width: 5.0));
        _flagRow.add(
          GestureDetector(
              onTap: () {
                if (i < 2)
                  switch (_flagStatus[i * 3 + j]) {
                    case 0:
                      _redScore.highFlag++;
                      break;
                    case 1:
                      _redScore.highFlag--;
                      _blueScore.highFlag++;
                      break;
                    case 2:
                      _blueScore.highFlag--;
                      break;
                  }
                else
                  switch (_flagStatus[i * 3 + j]) {
                    case 0:
                      _redScore.lowFlag++;
                      break;
                    case 1:
                      _redScore.lowFlag--;
                      _blueScore.lowFlag++;
                      break;
                    case 2:
                      _blueScore.lowFlag--;
                      break;
                  }
                _flagStatus[i * 3 + j]++;
                if (_flagStatus[i * 3 + j] > 2) _flagStatus[i * 3 + j] = 0;
                setState(() {});
              },
              child: Container(
                width: _flagWidth,
                child: Image.asset(
                  _getFlagStatus(_flagStatus[i * 3 + j]),
                  fit: BoxFit.scaleDown,
                ),
              )),
        );
      }
      _flagGrid.add(Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(children: _flagRow),
      ));
    }
    _updateTimer();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: <Widget>[
            Text(
              '8059 Blank. VRC 2019',
              style: TextStyle(color: Colors.white),
            ),
            Expanded(child: Container()),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _redScore.clear();
                _blueScore.clear();
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                showDialog<Null>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context2) {
                      return AlertDialog(
                        title: Text(
                          'Change Warning Timings',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Scrollbar(
                          child: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text(
                                  'Skills',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 50.0,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        controller: _skills,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (int.parse(value) > 60)
                                            return 'Invalid Time';
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 100.0,
                                      child: Text(
                                        'Seconds Left',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(height: 10.0),
                                Text(
                                  'Match',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 50.0,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        controller: _match,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (int.parse(value) > 105)
                                            return 'Invalid Time';
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 100.0,
                                      child: Text(
                                        'Seconds Left',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () => Navigator.of(context2).pop(),
                          ),
                          FlatButton(
                            child: Text(
                              'Save',
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () {
                              _saveTimes();
                              Navigator.of(context2).pop();
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(width: 15.0),
              Text(
                'Match: ',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Switch(
                activeColor: Colors.red,
                activeTrackColor: Colors.redAccent,
                inactiveThumbColor: Colors.grey[700],
                inactiveTrackColor: Colors.grey[500],
                value: _matchType,
                onChanged: (val) => setState(() {
                      _matchType = val;
                      _lastTime = Duration(seconds: 0);
                      _s.stop();
                      _s.reset();
                      _stopwatchStarted = false;
                    }),
              ),
              Expanded(child: Container()),
              Text(
                _d.inMinutes.toString() +
                    ':' +
                    (_d.inSeconds % 60).toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
              ),
              Expanded(child: Container()),
              _getStartStopButton(),
              Container(
                width: 50.0,
                height: 50.0,
                color: Colors.transparent,
                child: IconButton(
                    icon: Icon(Icons.replay),
                    onPressed: () {
                      _lastTime = Duration(seconds: 0);
                      _s.stop();
                      _s.reset();
                      _stopwatchStarted = false;
                    }),
              ),
              Container(width: 15.0),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (_autonWin == 1) {
                    _autonWin = 0;
                    _redScore.auton = false;
                  } else {
                    _autonWin = 1;
                    _redScore.auton = true;
                    _blueScore.auton = false;
                  }
                },
                child: Container(
                  width: _autonButtonWidth,
                  height: _autonButtonWidth,
                  child: Image.asset(
                    _redAuton(),
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 30.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomLeft: Radius.circular(7.0)),
                  color: Colors.red,
                ),
                width: _autonButtonWidth,
                height: _autonButtonWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Score',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _redScore.getScore().toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 30.0),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 30.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0)),
                  color: allianceBlue,
                ),
                width: _autonButtonWidth,
                height: _autonButtonWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Score',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _blueScore.getScore().toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 30.0),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_autonWin == 2) {
                    _autonWin = 0;
                    _blueScore.auton = false;
                  } else {
                    _autonWin = 2;
                    _blueScore.auton = true;
                    _redScore.auton = false;
                  }
                },
                child: Container(
                  width: _autonButtonWidth,
                  height: _autonButtonWidth,
                  child: Image.asset(
                    _blueAuton(),
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ],
          ),
          Container(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(width: 5.0),
              Column(
                children: <Widget>[
                  _slidingLevel(0),
                  Container(height: 20.0),
                  _slidingLevel(1),
                ],
              ),
              Container(width: 5.0),
              Column(
                children: <Widget>[
                  Column(children: _flagGrid),
                  Container(height: 20.0),
                  Row(
                    children: <Widget>[
                      Container(
                        child: Text(
                          _redScore.alliancePark.toString(),
                          style: TextStyle(
                              fontSize: 30.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(width: 5.0),
              Column(
                children: <Widget>[
                  _slidingLevel(2),
                  Container(height: 20.0),
                  _slidingLevel(3),
                ],
              ),
              Container(width: 5.0),
            ],
          ),
          Container(height: 10.0),
        ],
      ),
    );
  }

  String _getFlagStatus(int a) {
    if (a == 0) //None
      return 'images/flag_neutral.png';
    else if (a == 1) //Red
      return 'images/flag_red.png';
    else //Blue
      return 'images/flag_blue.png';
  }

  String _redAuton() {
    if (_autonWin == 1)
      return 'images/auton_red_enabled.png';
    else
      return 'images/auton_red_disabled.png';
  }

  String _blueAuton() {
    if (_autonWin == 2)
      return 'images/auton_blue_enabled.png';
    else
      return 'images/auton_blue_disabled.png';
  }

  GestureDetector _slidingLevel(int v) {
    int size = v == 0 ? 6 : v == 2 ? 6 : 8;
    return GestureDetector(
      onPanStart: (DragStartDetails d) {
        _panning = true;
        _initCaps[v] = d.globalPosition.dy;
        _initVal[v] = _getCapScore(v);
        //debugPrint('init: ' + _initVal[v].toString());
      },
      onPanUpdate: (DragUpdateDetails d) {
        double _dist = _initCaps[v] - d.globalPosition.dy;
        int _num = (_dist / _boxHeight).round(); //TODO change 30.0
        /*
        debugPrint(_initVal[v].toString());
        debugPrint(_num.toString());
        debugPrint('-------------------');
        */
        int output = _initVal[v] + _num;
        if (output < 0)
          output = 0;
        else if (output > size) output = size;
        switch (v) {
          case 0:
            setState(() => _redScore.highCap = output);
            break;
          case 1:
            setState(() => _redScore.lowCap = output);
            break;
          case 2:
            setState(() => _blueScore.highCap = output);
            break;
          case 3:
            setState(() => _blueScore.lowCap = output);
            break;
        }
      },
      onPanEnd: (DragEndDetails d) {
        _initCaps[v] = 0.0;
        _panning = false;
      },
      child: CapLevel(size, _getCapScore(v), v < 2),
    );
  }

  int _getCapScore(int v) {
    switch (v) {
      case 0:
        return _redScore.highCap;
        break;
      case 1:
        return _redScore.lowCap;
        break;
      case 2:
        return _blueScore.highCap;
        break;
      case 3:
        return _blueScore.lowCap;
        break;
    }
    return 0;
  }

  Container _getStartStopButton() {
    if (!_stopwatchStarted)
      return Container(
        width: 50.0,
        height: 50.0,
        color: Colors.transparent,
        child: IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              _s.start();
              _stopwatchStarted = true;
            }),
      );
    else
      return Container(
        width: 50.0,
        height: 50.0,
        color: Colors.transparent,
        child: IconButton(
            icon: Icon(Icons.pause),
            onPressed: () {
              _lastTime = _s.elapsed;
              _s.stop();
              _stopwatchStarted = false;
            }),
      );
  }

  Future<void> _updateTimer() async {
    await Future.delayed(Duration(milliseconds: 300));
    setState(() => {});
  }
}
