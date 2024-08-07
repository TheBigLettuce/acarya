// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/pages/more/settings/settings_label.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class TimeLabel extends StatelessWidget {
  const TimeLabel(
    this.time,
    this.titleStyle,
    this.now, {
    super.key,
    this.removePadding = false,
  });

  final (int, int, int) time;
  final TextStyle titleStyle;
  final DateTime now;
  final bool removePadding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (time == (now.day, now.month, now.year)) {
      return SettingsLabel(
        l10n.todayLabel,
        titleStyle,
        removePadding: removePadding,
      );
    } else {
      return SettingsLabel(
        l10n.dateSimple(DateTime(time.$3, time.$2, time.$1)),
        titleStyle,
        removePadding: removePadding,
      );
    }
  }
}
