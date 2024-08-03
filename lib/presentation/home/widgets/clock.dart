import 'dart:async';

import 'package:absenq/core/core.dart';
import 'package:flutter/material.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({Key? key}) : super(key: key);

  @override
  _ClockWidgetState createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _currentTime.toFormattedTime(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size.width / 25,
            color: AppColors.white,
          ),
        ),
        Text(
          _currentTime.toFormattedDate(),
          style: TextStyle(
            color: AppColors.white,
            fontSize: size.width / 30,
          ),
        ),
      ],
    );
  }
}
