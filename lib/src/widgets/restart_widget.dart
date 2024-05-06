// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/services/services.dart";

/// RestartWidget is needed for changing the boorus in the settings.
class RestartWidget extends StatefulWidget {
  const RestartWidget({
    super.key,
    required this.accentColor,
    required this.child,
  });
  final Color accentColor;
  final Widget Function(ThemeData dark, ThemeData light, SettingsData settings)
      child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  bool inBackground = false;
  int stepsToSave = 0;

  static const int _maxSteps = 10;

  late final AppLifecycleListener listener;
  late final StreamSubscription<void> timeTicker;
  final StreamController<Duration> timeListener = StreamController.broadcast();
  Duration currentDuration = Duration.zero;
  DateTime timeNow = DateTime.now();

  @override
  void initState() {
    super.initState();

    StatisticsDailyData sts = currentDb.statisticsDaily.current;

    if (timeNow.day != sts.date.day ||
        timeNow.month != sts.date.month ||
        timeNow.year != sts.date.year) {
      sts = sts.copy(durationMillis: 0, swipedBoth: 0, date: timeNow)..save();
    }

    currentDuration = Duration(milliseconds: sts.durationMillis);

    timeTicker =
        Stream<void>.periodic(const Duration(seconds: 1)).listen((event) {
      if (!inBackground) {
        bool switchDate = false;

        stepsToSave += 1;

        currentDuration = currentDuration + const Duration(seconds: 1);

        final nextTime = DateTime.now();

        if (timeNow.day != nextTime.day ||
            timeNow.month != nextTime.month ||
            timeNow.year != nextTime.year) {
          timeNow = nextTime;
          currentDuration = Duration.zero;
          switchDate = true;
        }

        timeListener.sink.add(currentDuration);

        if (stepsToSave >= _maxSteps || switchDate) {
          if (switchDate) {
            currentDb.statisticsDaily.current
                .copy(durationMillis: 1, swipedBoth: 0, date: timeNow)
                .save();
          } else {
            currentDb.statisticsDaily.current
                .copy(durationMillis: currentDuration.inMilliseconds)
                .save();
          }

          stepsToSave = 0;
        }

        if (switchDate) {
          setState(() {});
        }
      }
    });

    listener = AppLifecycleListener(
      onHide: () {
        inBackground = true;
      },
      onShow: () {
        inBackground = false;
      },
    );
  }

  @override
  void dispose() {
    timeListener.close();
    timeTicker.cancel();
    listener.dispose();

    super.dispose();
  }

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  Duration _c() => currentDuration;

  @override
  Widget build(BuildContext context) {
    final d = buildTheme(Brightness.dark, widget.accentColor);
    final l = buildTheme(Brightness.light, widget.accentColor);

    return DatabaseConnectionNotifier.current(
      TimeSpentNotifier(
        timeNow,
        ticker: timeListener.stream,
        current: _c,
        child: KeyedSubtree(
          key: key,
          child: ColoredBox(
            color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
                ? d.colorScheme.background
                : l.colorScheme.background,
            child: widget
                .child(d, l, SettingsService.currentData)
                .animate(effects: [const FadeEffect()]),
          ),
        ),
      ),
    );
  }
}

class TimeSpentNotifier extends InheritedWidget {
  const TimeSpentNotifier(
    this._time, {
    super.key,
    required this.ticker,
    required this.current,
    required super.child,
  });
  final Stream<Duration> ticker;
  final Duration Function() current;
  final DateTime _time;

  static (Duration, Stream<Duration>) streamOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TimeSpentNotifier>();

    return (widget!.current(), widget.ticker);
  }

  @override
  bool updateShouldNotify(TimeSpentNotifier oldWidget) =>
      ticker != oldWidget.ticker ||
      current != oldWidget.current ||
      _time != oldWidget._time;
}
