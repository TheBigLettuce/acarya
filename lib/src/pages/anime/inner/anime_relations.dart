// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/pages/anime/inner/anime_inner.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';

class AnimeRelations extends StatelessWidget {
  final AnimeAPI api;
  final AnimeEntry entry;

  const AnimeRelations({super.key, required this.entry, required this.api});

  @override
  Widget build(BuildContext context) {
    return entry.relations.isEmpty
        ? const SizedBox.shrink()
        : Column(
            children: [
              const BodySegmentLabel(text: "Related"),
              ...entry.relations.map(
                (e) => TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return SearchAnimePage(api: api, initalText: e.title);
                      },
                    ));
                  },
                  child: Text(
                    e.type.isNotEmpty ? "${e.title} (${e.type})" : e.title,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8)),
                  ),
                ),
              ),
            ],
          );
  }
}
