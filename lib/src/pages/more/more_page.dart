// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';

import '../../widgets/azari_icon.dart';
import 'dashboard/dashboard.dart';
import 'downloads.dart';
import 'blacklisted_page.dart';
import 'settings/settings_widget.dart';

class MorePage extends StatelessWidget {
  final SelectionGlue<J> Function<J extends Cell>() generateGlue;

  const MorePage({
    super.key,
    required this.generateGlue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AzariIcon(color: Theme.of(context).colorScheme.primary),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.dashboard_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.dashboardPage),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const Dashboard();
                },
              ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.download_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.downloadsPageName),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return Downloads(
                    generateGlue: generateGlue,
                  );
                },
              ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.hide_image_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.blacklistedPage),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlacklistedPage(
                      generateGlue: generateGlue,
                    ),
                  ));
            },
          ),
          const Divider(),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.settingsPageName),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                builder: (context) {
                  return const SettingsWidget();
                },
              ));
            },
          )
        ],
      ),
    );
  }
}
