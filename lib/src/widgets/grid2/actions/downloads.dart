// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';

import '../../../net/downloader.dart';
import '../metadata/grid_action.dart';

class DownloadsActions {
  static GridAction<DownloadFile> retryOrDelete(BuildContext context) {
    return GridAction(Icons.more_horiz, (selected) {
      if (selected.isEmpty) {
        return;
      }
      final file = selected.first;
      Navigator.push(
          context,
          DialogRoute(
              context: context,
              builder: (context) {
                return AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.no)),
                    TextButton(
                        onPressed: () {
                          Downloader.g.retry(file, Settings.fromDb());
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.yes)),
                  ],
                  title: Text(Downloader.g.downloadAction(file)),
                  content: Text(file.name),
                );
              }));
    }, true, showOnlyWhenSingle: true);
  }
}
