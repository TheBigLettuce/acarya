// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/schemas/gallery/directory_metadata.dart';
import 'package:gallery/src/db/schemas/grid_settings/directories.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/pages/more/favorite_booru_actions.dart';
import 'package:gallery/src/pages/gallery/gallery_directories_actions.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/pages/gallery/files.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/gallery/favorite_booru_post.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:local_auth/local_auth.dart';

import '../../db/schemas/settings/settings.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../widgets/skeletons/grid.dart';
import 'callback_description.dart';
import 'callback_description_nested.dart';

class GalleryDirectories extends StatefulWidget {
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool showBackButton;
  final void Function(bool) procPop;
  final bool wrapGridPage;

  const GalleryDirectories({
    super.key,
    this.callback,
    this.nestedCallback,
    required this.procPop,
    this.wrapGridPage = false,
    this.showBackButton = false,
  }) : assert(!(callback != null && nestedCallback != null));

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories> {
  static const _log = LogTarget.gallery;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription<MiscSettings?> miscSettingsWatcher;
  late final AppLifecycleListener lifecycleListener;

  MiscSettings miscSettings = MiscSettings.current;

  int galleryVersion = 0;

  GridMutationInterface<SystemGalleryDirectory> get mutation =>
      state.refreshingStatus.mutation;

  bool proceed = true;
  late final extra = api.getExtra()
    ..setRefreshGridCallback(() {
      if (widget.callback != null) {
        mutation.cellCount = 0;
        mutation.isRefreshing = true;
      } else {
        if (!mutation.isRefreshing) {
          _refresh();
        }
      }
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectory> state =
      GridSkeletonStateFilter(
    transform: (cell) => cell,
    filter: extra.filter,
    initalCellCount: widget.callback != null
        ? extra.db.systemGalleryDirectorys.countSync()
        : 0,
  );

  final galleryPlug = chooseGalleryPlug();

  late final SearchFilterGrid<SystemGalleryDirectory> search;

  late final api = galleryPlug.galleryApi(
      temporaryDb: widget.callback != null || widget.nestedCallback != null,
      setCurrentApi: widget.callback == null);
  bool isThumbsLoading = false;

  int? trashThumbId;

  @override
  void initState() {
    super.initState();

    galleryPlug.version.then((value) => galleryVersion = value);

    lifecycleListener = AppLifecycleListener(
      onShow: () {
        galleryPlug.version.then((value) {
          if (value != galleryVersion) {
            galleryVersion = value;
            _refresh();
          }
        });
      },
    );

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;
      setState(() {});
    });

    miscSettingsWatcher = MiscSettings.watch((s) {
      miscSettings = s!;

      setState(() {});
    });

    search = SearchFilterGrid(state, null);

    if (widget.callback != null) {
      search.performSearch("", true);

      extra.setTemporarySet((i, end) {
        if (end) {
          mutation.isRefreshing = false;
          search.performSearch(search.searchTextController.text);
        }
      });
    }

    if (widget.callback != null) {
      PlatformFunctions.trashThumbId().then((value) {
        try {
          setState(() {
            trashThumbId = value;
          });
        } catch (_) {}
      });
    }

    extra.setRefreshingStatusCallback((i, inRefresh, empty) {
      state.gridKey.currentState?.selection.reset();

      if (!inRefresh || empty) {
        mutation.isRefreshing = false;
        search.performSearch(search.searchTextController.text);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    miscSettingsWatcher.cancel();

    api.close();
    search.dispose();
    state.dispose();
    Dbs.g.clearTemporaryImages();
    lifecycleListener.dispose();

    super.dispose();
  }

  void _refresh() {
    PlatformFunctions.trashThumbId().then((value) {
      try {
        setState(() {
          trashThumbId = value;
        });
      } catch (_) {}
    });

    mutation.isRefreshing = true;
    api.refresh();
    galleryPlug.version.then((value) => galleryVersion = value);
  }

  String _segmentFnc(SystemGalleryDirectory cell) {
    for (final booru in Booru.values) {
      if (booru.url == cell.name) {
        return "Booru";
      }
    }

    final dirTag = PostTags.g.directoryTag(cell.bucketId);
    if (dirTag != null) {
      return dirTag;
    }

    final name = cell.name.split(" ");
    return name.first.toLowerCase();
  }

  Segments<SystemGalleryDirectory> _makeSegments(BuildContext context) {
    return Segments(
      AppLocalizations.of(context)!.segmentsUncategorized,
      injectedLabel: widget.callback != null || widget.nestedCallback != null
          ? "Suggestions"
          : AppLocalizations.of(context)!.segmentsSpecial, // TODO: change
      displayFirstCellInSpecial:
          widget.callback != null || widget.nestedCallback != null,
      caps:
          DirectoryMetadata.caps(AppLocalizations.of(context)!.segmentsSpecial),
      segment: _segmentFnc,

      injectedSegments: [
        if (FavoriteBooruPost.isNotEmpty())
          SystemGalleryDirectory(
            bucketId: "favorites",
            name: AppLocalizations.of(context)!
                .galleryDirectoriesFavorites, // change
            tag: "",
            volumeName: "",
            relativeLoc: "",
            lastModified: 0,
            thumbFileId: miscSettings.favoritesThumbId != 0
                ? miscSettings.favoritesThumbId
                : FavoriteBooruPost.thumbnail,
          ),
        if (trashThumbId != null)
          SystemGalleryDirectory(
            bucketId: "trash",
            name: AppLocalizations.of(context)!.galleryDirectoryTrash, // change
            tag: "",
            volumeName: "",
            relativeLoc: "",
            lastModified: 0,
            thumbFileId: trashThumbId!,
          ),
      ],
      onLabelPressed: widget.callback != null && !widget.callback!.joinable
          ? null
          : (label, children) =>
              SystemGalleryDirectoriesActions.joinedDirectoriesFnc(
                context,
                label,
                children,
                extra,
                widget.nestedCallback,
                GlueProvider.generateOf(context),
                _segmentFnc,
              ),
    );
  }

  void _addToGroup(BuildContext context, List<SystemGalleryDirectory> selected,
      String value, bool toPin) async {
    final requireAuth = <SystemGalleryDirectory>[];
    final noAuth = <SystemGalleryDirectory>[];

    for (final e in selected) {
      final m = DirectoryMetadata.get(_segmentFnc(e));
      if (m != null && m.requireAuth) {
        requireAuth.add(e);
      } else {
        noAuth.add(e);
      }
    }

    if (noAuth.isEmpty && requireAuth.isNotEmpty && canAuthBiometric) {
      final success = await LocalAuthentication()
          .authenticate(localizedReason: "Change directories group");
      if (!success) {
        return;
      }
    }

    if (value.isEmpty) {
      PostTags.g.removeDirectoriesTag(
          (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
              .map((e) => e.bucketId));
    } else {
      PostTags.g.setDirectoriesTag(
          (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
              .map((e) => e.bucketId),
          value);

      if (toPin) {
        if (await DirectoryMetadata.canAuth(value, "Sticky directory")) {
          final m = (DirectoryMetadata.get(value) ??
                  DirectoryMetadata(value, DateTime.now(),
                      blur: false, sticky: false, requireAuth: false))
              .copyBools(sticky: true);
          m.save();
        }
      }
    }

    if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Some directories require authentication"),
        action: SnackBarAction(
            label: "Auth",
            onPressed: () async {
              final success = await LocalAuthentication()
                  .authenticate(localizedReason: "Change group on directories");
              if (!success) {
                return;
              }

              if (value.isEmpty) {
                PostTags.g
                    .removeDirectoriesTag(requireAuth.map((e) => e.bucketId));
              } else {
                PostTags.g.setDirectoriesTag(
                    requireAuth.map((e) => e.bucketId), value);
              }

              _refresh();
            }),
      ));
    }

    _refresh();

    Navigator.of(context, rootNavigator: true).pop();
  }

  Widget child(BuildContext context) {
    return GridSkeleton<SystemGalleryDirectory>(
      state,
      (context) => GridFrame(
        key: state.gridKey,
        layout: SegmentLayout(
          _makeSegments(context),
          GridSettingsDirectories.current,
          suggestionPrefix: widget.callback?.suggestFor ?? const [],
        ),
        getCell: (i) => api.directCell(i),
        functionality: GridFunctionality(
            onPressed: OverrideGridOnCellPressBehaviour(
                onPressed: (context, idx, providedCell) async {
              final cell = providedCell as SystemGalleryDirectory? ??
                  CellProvider.getOf<SystemGalleryDirectory>(context, idx);

              if (widget.callback != null) {
                state.refreshingStatus.mutation.cellCount = 0;

                Navigator.pop(context);
                widget.callback!.c(cell, null);
              } else {
                if (!await DirectoryMetadata.canAuth(
                    _segmentFnc(cell), "Open directory")) {
                  return;
                }

                StatisticsGallery.addViewedDirectories();
                final d = cell;

                final apiFiles = switch (cell.bucketId) {
                  "trash" => extra.trash(),
                  "favorites" => extra.favorites(),
                  String() => api.files(d),
                };

                final glue = GlueProvider.generateOf(context);

                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => switch (cell.bucketId) {
                        "favorites" => GalleryFiles(
                            generateGlue: glue,
                            api: apiFiles,
                            callback: widget.nestedCallback,
                            dirName: AppLocalizations.of(context)!
                                .galleryDirectoriesFavorites,
                            bucketId: "favorites",
                          ),
                        "trash" => GalleryFiles(
                            api: apiFiles,
                            generateGlue: glue,
                            callback: widget.nestedCallback,
                            dirName: AppLocalizations.of(context)!
                                .galleryDirectoryTrash,
                            bucketId: "trash",
                          ),
                        String() => GalleryFiles(
                            generateGlue: glue,
                            api: apiFiles,
                            dirName: d.name,
                            callback: widget.nestedCallback,
                            bucketId: d.bucketId,
                          )
                      },
                    ));
              }
            }),
            selectionGlue: GlueProvider.generateOf(context)(),
            refreshingStatus: state.refreshingStatus,
            imageViewDescription: ImageViewDescription(
              imageViewKey: state.imageViewKey,
            ),
            watchLayoutSettings: GridSettingsDirectories.watch,
            refresh: widget.callback != null
                ? SynchronousGridRefresh(() {
                    PlatformFunctions.trashThumbId().then((value) {
                      try {
                        setState(() {
                          trashThumbId = value;
                        });
                      } catch (_) {}
                    });

                    return extra.db.systemGalleryDirectorys.countSync();
                  })
                : RetainedGridRefresh(_refresh),
            search: OverrideGridSearchWidget(
              SearchAndFocus(
                  search.searchWidget(context,
                      count: widget.callback != null
                          ? extra.db.systemGalleryDirectorys.countSync()
                          : null,
                      hint: AppLocalizations.of(context)!.directoriesHint),
                  search.searchFocus),
            )),
        mainFocus: state.mainFocus,
        description: GridDescription(
          risingAnimation:
              widget.nestedCallback == null && widget.callback == null,
          actions: widget.callback != null || widget.nestedCallback != null
              ? [
                  if (widget.callback == null || widget.callback!.joinable)
                    SystemGalleryDirectoriesActions.joinedDirectories(
                      context,
                      extra,
                      widget.nestedCallback,
                      GlueProvider.generateOf(context),
                      _segmentFnc,
                    )
                ]
              : [
                  FavoritesActions.addToGroup(context, (selected) {
                    final t = (selected.first as SystemGalleryDirectory).tag;
                    for (final SystemGalleryDirectory e
                        in selected.skip(1).cast()) {
                      if (t != e.tag) {
                        return null;
                      }
                    }

                    return t;
                  }, (s, v, t) => _addToGroup(context, s.cast(), v, t), true),
                  SystemGalleryDirectoriesActions.blacklist(
                      context, extra, _segmentFnc),
                  SystemGalleryDirectoriesActions.joinedDirectories(
                    context,
                    extra,
                    widget.nestedCallback,
                    GlueProvider.generateOf(context),
                    _segmentFnc,
                  )
                ],
          footer: widget.callback?.preview,
          menuButtonItems: [
            if (widget.callback != null)
              IconButton(
                  onPressed: () async {
                    try {
                      widget.callback!(
                        null,
                        await PlatformFunctions.chooseDirectory(temporary: true)
                            .then((value) => value!.path),
                      );
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    } catch (e, trace) {
                      _log.logDefaultImportant(
                          "new folder in android_directories".errorMessage(e),
                          trace);

                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.create_new_folder_outlined)),
          ],
          bottomWidget: widget.callback != null || widget.nestedCallback != null
              ? CopyMovePreview.hintWidget(
                  context,
                  widget.callback != null
                      ? widget.callback!.description
                      : widget.nestedCallback!.description)
              : null,
          settingsButton: GridFrameSettingsButton(
            selectRatio: (ratio, settings) =>
                (settings as GridSettingsDirectories)
                    .copy(aspectRatio: ratio)
                    .save(),
            selectHideName: (hideNames, settings) =>
                (settings as GridSettingsDirectories)
                    .copy(hideName: hideNames)
                    .save(),
            selectGridLayout: null,
            selectGridColumn: (columns, settings) =>
                (settings as GridSettingsDirectories)
                    .copy(columns: columns)
                    .save(),
          ),
          inlineMenuButtonItems: true,
          keybindsDescription:
              AppLocalizations.of(context)!.androidGKeybindsDescription,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: widget.callback != null || widget.nestedCallback != null
          ? search.currentFilteringMode() == FilteringMode.noFilter &&
              search.searchTextController.text.isEmpty
          : false,
      onPop: (pop) {
        final filterMode = search.currentFilteringMode();
        if (filterMode != FilteringMode.noFilter ||
            search.searchTextController.text.isNotEmpty) {
          search.resetSearch();
          return;
        }

        widget.procPop(pop);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.wrapGridPage
        ? WrapGridPage(
            addScaffold: widget.callback != null,
            child: Builder(
              builder: (context) => child(context),
            ),
          )
        : child(context);
  }
}
