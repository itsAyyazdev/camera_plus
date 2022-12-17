import 'package:camera_plus/library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';

class MyCountDown extends StatefulWidget {
  final int allowedTimeInSeconds;
  final Function onEnd;
  const MyCountDown(
      {Key? key, required this.allowedTimeInSeconds, required this.onEnd})
      : super(key: key);

  @override
  State<MyCountDown> createState() => _MyCountDownState();
}

class _MyCountDownState extends State<MyCountDown> {
  late int seconds;

  @override
  void initState() {
    seconds = DateTime.now()
        .add(Duration(seconds: widget.allowedTimeInSeconds))
        .millisecondsSinceEpoch;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CountdownTimer(
      endTime: seconds,
      widgetBuilder: (context, crt) {
        if (crt != null) {
          return Text(
            "${crt.min ?? "00"}:${crt.sec! < 10 ? "0${crt.sec}" : crt.sec ?? "0"}",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
                shadows: [
                  BoxShadow(color: Colors.black.withOpacity(0.6)),
                  BoxShadow(color: Colors.black54.withOpacity(0.6)),
                  BoxShadow(color: Colors.black54.withOpacity(0.6)),
                ]),
          );
        } else {
          return const SizedBox();
        }
      },
      onEnd: () {
        appLogger("Recording ended::::");
        widget.onEnd();
      },
    );
  }
}
