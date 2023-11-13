// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/widgets/grid/selection_interface.dart';
import 'package:gallery/src/widgets/image_view/loading_builder.dart';
import 'package:gallery/src/widgets/image_view/make_image_view_bindings.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_notifiers.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_skeleton.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_theme.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/notifiers/cell_provider.dart';
import 'package:gallery/src/widgets/notifiers/grid_element_count.dart';
import 'package:gallery/src/widgets/notifiers/grid_metadata.dart';
import 'package:gallery/src/widgets/notifiers/notes_interface.dart';
import 'package:logging/logging.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/keybinds/keybind_description.dart';
import '../interfaces/cell.dart';
import '../interfaces/contentable.dart';
import '../widgets/keybinds/describe_keys.dart';
import '../widgets/image_view/app_bar.dart';
import '../widgets/image_view/body.dart';
import '../widgets/image_view/bottom_bar.dart';
import '../widgets/image_view/end_drawer.dart';
import '../widgets/image_view/page_type_mixin.dart';
import '../widgets/image_view/palette_mixin.dart';
import '../widgets/image_view/note_list.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class NoteInterface<T extends Cell> {
  final void Function(
      String text, T cell, Color? backgroundColor, Color? textColor) addNote;
  final NoteBase? Function(T cell) load;
  final void Function(T cell, int indx, String newCell) replace;
  final void Function(T cell, int indx) delete;
  final void Function(T cell, int from, int to) reorder;

  const NoteInterface(
      {required this.addNote,
      required this.delete,
      required this.load,
      required this.replace,
      required this.reorder});
}

class ImageView<T extends Cell> extends StatefulWidget {
  final Future<int> Function()? onNearEnd;
  // final List<GridAction<T>> Function(T)? addIcons;
  final void Function(int i)? download;
  final void Function(ImageViewState<T> state)? pageChange;
  final void Function() onExit;
  final void Function() focusMain;

  final List<int>? predefinedIndexes;

  final void Function()? onEmptyNotes;

  final int startingCell;
  final T currentCell;

  const ImageView({
    super.key,
    required this.onExit,
    this.predefinedIndexes,
    required this.onNearEnd,
    required this.currentCell,
    required this.focusMain,
    this.pageChange,
    required this.startingCell,
    this.onEmptyNotes,
    this.download,
    // this.addIcons
  });

  @override
  State<ImageView<T>> createState() => ImageViewState<T>();
}

class ImageViewState<T extends Cell> extends State<ImageView<T>>
    with
        ImageViewPageTypeMixin<T>,
        ImageViewPaletteMixin<T>,
        ImageViewLoadingBuilderMixin<T> {
  final mainFocus = FocusNode();
  final scrollController = ScrollController();

  late final controller = PageController(initialPage: widget.startingCell);

  final GlobalKey<ScaffoldState> key = GlobalKey();
  final GlobalKey<WrapImageViewNotifiersState> wrapNotifiersKey = GlobalKey();
  final GlobalKey<WrapImageViewThemeState> wrapThemeKey = GlobalKey();
  final GlobalKey<NoteListState> noteListKey = GlobalKey();

  PlatformFullscreensPlug? fullscreenPlug;

  late T currentCell = widget.currentCell;
  late int currentPage = widget.startingCell;

  final noteTextController = TextEditingController();

  bool refreshing = false;

  Map<ShortcutActivator, void Function()>? bindings;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      // if (widget.infoScrollOffset != null) {
      //   key.currentState?.openEndDrawer();
      // }

      fullscreenPlug = choosePlatformFullscreenPlug(
          Theme.of(context).colorScheme.surface.withOpacity(0.8));

      fullscreenPlug?.setTitle(currentCell.alias(true));
      _loadNext(widget.startingCell);

      final b = makeImageViewBindings(context, key, controller,
          download: widget.download == null
              ? null
              : () => widget.download!(currentPage),
          onTap: _onTap);
      bindings = {
        ...b,
        ...keybindDescription(context, describeKeys(b),
            AppLocalizations.of(context)!.imageViewPageName, widget.focusMain)
      };

      noteListKey.currentState?.loadNotes(currentCell);

      setState(() {});

      extractPalette(context, currentCell, key, scrollController, currentPage,
          _resetAnimation);
    });

    // StateRestorationProvider.maybeOf(context).

    // widget.updateTagScrollPos(null, widget.startingCell);
  }

  @override
  void dispose() {
    fullscreenPlug?.unfullscreen();

    WakelockPlus.disable();
    // widget.updateTagScrollPos(null, null);
    controller.dispose();

    widget.onExit();

    scrollController.dispose();

    super.dispose();
  }

  void _resetAnimation() {
    wrapThemeKey.currentState?.resetAnimation();
  }

  void hardRefresh() {
    fakeProvider = MemoryImage(kTransparentImage);

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        fakeProvider = null;
      });
    });
  }

  void refreshImage() {
    var i = currentCell.fileDisplay(context);
    if (i is NetImage) {
      PaintingBinding.instance.imageCache.evict(i.provider);

      hardRefresh();
    }
  }

  // void update(BuildContext context, int count, {bool pop = true}) {
  //   if (count == 0) {
  //     if (pop) {
  //       key.currentState?.closeEndDrawer();
  //       Navigator.pop(context);
  //     }
  //     return;
  //   }

  //   // cellCount = count;

  //   if (count == 1) {
  //     final newCell = CellProvider.getOf<T>(context, 0);
  //     if (newCell == currentCell) {
  //       return;
  //     }
  //     controller.previousPage(duration: 200.ms, curve: Curves.linearToEaseOut);

  //     currentCell = newCell;
  //     hardRefresh();
  //   } else if (currentPage > count - 1) {
  //     controller.previousPage(duration: 200.ms, curve: Curves.linearToEaseOut);
  //   } else if (CellProvider.getOf<T>(context, currentPage)
  //           .getCellData(false, context: context)
  //           .thumb !=
  //       currentCell.getCellData(false, context: context).thumb) {
  //     if (currentPage == 0) {
  //       controller.nextPage(
  //           duration: 200.ms, curve: Curves.fastLinearToSlowEaseIn);
  //     } else {
  //       controller.previousPage(
  //           duration: 200.ms, curve: Curves.linearToEaseOut);
  //     }
  //   } else {
  //     currentCell = CellProvider.getOf<T>(context, currentPage);
  //   }

  //   setState(() {});
  // }

  void _loadNext(int index) {
    if (index >= GridElementCountNotifier.of(context) - 3 &&
        !refreshing &&
        widget.onNearEnd != null) {
      setState(() {
        refreshing = true;
      });
      widget.onNearEnd!().then((value) {
        if (context.mounted) {
          setState(() {
            refreshing = false;
          });
        }
      }).onError((error, stackTrace) {
        log("loading next in the image view page",
            level: Level.WARNING.value, error: error, stackTrace: stackTrace);
      });
    }
  }

  void _onTap() {
    fullscreenPlug?.fullscreen();
    wrapNotifiersKey.currentState?.toggle();
  }

  void _onTagRefresh() {
    try {
      setState(() {});
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    noteListKey.currentState?.unextendNotes();
    currentPage = index;
    widget.pageChange?.call(this);
    _loadNext(index);
    // widget.updateTagScrollPos(null, index);

    // widget.scrollUntill(index);

    final c = CellProvider.getOf<T>(context, index);

    fullscreenPlug?.setTitle(c.alias(true));

    setState(() {
      currentCell = c;
      noteListKey.currentState?.loadNotes(currentCell);

      extractPalette(context, currentCell, key, scrollController, currentPage,
          _resetAnimation);
    });
  }

  void _onLongPress() {
    if (widget.download == null) {
      return;
    }

    HapticFeedback.vibrate();
    widget.download!(currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return WrapImageViewNotifiers<T>(
      key: wrapNotifiersKey,
      onTagRefresh: _onTagRefresh,
      currentCell: currentCell,
      child: WrapImageViewTheme(
        key: wrapThemeKey,
        currentPalette: currentPalette,
        previousPallete: previousPallete,
        child: WrapImageViewSkeleton(
            scaffoldKey: key,
            bindings: bindings ?? {},
            appBar: PreferredSize(
                preferredSize: currentStickers == null
                    ? const Size.fromHeight(kToolbarHeight + 4)
                    : const Size.fromHeight(kToolbarHeight + 36 + 4),
                child: ImageViewAppBar<T>(
                  stickers: currentStickers ?? const [],
                  actions: addButtons ?? const [],
                )),
            endDrawer: addInfo == null || addInfo!.isEmpty
                ? null
                : ImageViewEndDrawer(
                    scrollController: scrollController,
                    children: addInfo!,
                  ),
            bottomAppBar: ImageViewBottomAppBar(
                textController: noteTextController,
                addNote: () => noteListKey.currentState
                    ?.addNote(currentCell, currentPalette),
                showAddNoteButton:
                    NoteInterfaceProvider.maybeOf<T>(context) != null,
                // widget.noteInterface != null,
                children: GridMetadataProvider.gridActionsOf<T>(context).map(
                  (e) {
                    final extra = e.testSingle?.call(currentCell);

                    return WrapGridActionButton(extra?.overrideIcon ?? e.icon,
                        () {
                      e.onPress([currentCell]);
                    }, false, "",
                        followColorTheme: true,
                        color: extra?.color,
                        play: extra?.play ?? false,
                        backgroundColor: extra?.backgroundColor,
                        animate: extra?.animate ?? false);
                  },
                ).toList()),
            mainFocus: mainFocus,
            child: ImageViewBody(
              onPageChanged: _onPageChanged,
              onLongPress: _onLongPress,
              pageController: controller,
              notes: NoteInterfaceProvider.maybeOf<T>(context) == null
                  ? null
                  : NoteList<T>(
                      key: noteListKey,
                      noteInterface: NoteInterfaceProvider.maybeOf<T>(context)!,
                      onEmptyNotes: widget.onEmptyNotes,
                      backgroundColor: currentPalette?.dominantColor?.color
                              .harmonizeWith(
                                  Theme.of(context).colorScheme.primary) ??
                          Colors.black,
                    ),
              loadingBuilder: (context, event, idx) => loadingBuilder(context,
                  event, idx, currentPage, wrapNotifiersKey, currentPalette),
              itemCount: GridElementCountNotifier.of(context),
              onTap: _onTap,
              builder: galleryBuilder,
              decoration: BoxDecoration(
                color: currentPalette?.mutedColor?.color
                    .harmonizeWith(Theme.of(context).colorScheme.primary)
                    .withOpacity(0.7),
              ),
            )),
      ),
    );
  }
}
