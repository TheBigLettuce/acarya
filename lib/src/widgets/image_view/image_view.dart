// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/plugs/platform_fullscreens.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/body.dart";
import "package:gallery/src/widgets/image_view/mixins/loading_builder.dart";
import "package:gallery/src/widgets/image_view/mixins/page_type_mixin.dart";
import "package:gallery/src/widgets/image_view/mixins/palette.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_skeleton.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_theme.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart";
import "package:logging/logging.dart";
import "package:wakelock_plus/wakelock_plus.dart";

class ImageViewStatistics {
  const ImageViewStatistics({required this.swiped, required this.viewed});
  final void Function() swiped;
  final void Function() viewed;
}

abstract interface class ImageViewContentable {
  Contentable content(BuildContext context);
}

@immutable
class ImageViewDescription<T extends ContentableCell> {
  const ImageViewDescription({
    this.pageChange,
    this.beforeRestore,
    this.onExit,
    this.statistics,
    this.ignoreOnNearEnd = true,
  });

  final bool ignoreOnNearEnd;

  final void Function()? onExit;

  final void Function()? beforeRestore;

  final ImageViewStatistics? statistics;

  final void Function(ImageViewState state)? pageChange;
}

abstract interface class ContentableCell
    implements ImageViewContentable, CellBase {}

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    required this.cellCount,
    required this.scrollUntill,
    required this.startingCell,
    this.onExit,
    this.statistics,
    this.tags,
    this.updates,
    this.watchTags,
    this.ignoreLoadingBuilder = false,
    required this.getCell,
    required this.onNearEnd,
    this.pageChange,
    this.download,
    this.registerNotifiers,
    this.onRightSwitchPageEnd,
    this.onLeftSwitchPageEnd,
    this.gridContext,
  });
  final int startingCell;
  final Contentable? Function(BuildContext context, int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final Future<int> Function()? onNearEnd;
  final void Function(int i)? download;
  final void Function(ImageViewState state)? pageChange;
  final void Function()? onExit;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final ImageViewStatistics? statistics;

  final BuildContext? gridContext;

  final bool ignoreLoadingBuilder;

  final void Function()? onRightSwitchPageEnd;
  final void Function()? onLeftSwitchPageEnd;

  final StreamSubscription<int> Function(void Function(int) f)? updates;

  final List<ImageTag> Function(Contentable)? tags;
  final StreamSubscription<List<ImageTag>> Function(
    Contentable,
    void Function(List<ImageTag> l),
  )? watchTags;

  static Future<void> launchWrapped(
    BuildContext context,
    int cellCount,
    Contentable Function(BuildContext, int) cell, {
    int startingCell = 0,
    void Function(int)? download,
    Key? key,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          return GlueProvider.empty(
            context,
            child: ImageView(
              key: key,
              cellCount: cellCount,
              download: download,
              scrollUntill: (_) {},
              startingCell: startingCell,
              onExit: () {},
              getCell: cell,
              onNearEnd: null,
            ),
          );
        },
      ),
    );
  }

  static Future<void> defaultForGrid<T extends ContentableCell>(
    BuildContext gridContext,
    GridFunctionality<T> functionality,
    ImageViewDescription<T> imageDesctipion,
    int startingCell,
    List<ImageTag> Function(Contentable)? tags,
    StreamSubscription<List<ImageTag>> Function(
      Contentable,
      void Function(List<ImageTag> l),
    )? watchTags,
  ) {
    final extras = GridExtrasNotifier.of(gridContext);
    final config = GridConfigurationNotifier.of(gridContext);

    functionality.selectionGlue.hideNavBar(true);

    final getCell = CellProvider.of<T>(gridContext);

    return Navigator.of(gridContext, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ImageView(
            updates: functionality.refreshingStatus.mutation.listenCount,
            gridContext: gridContext,
            statistics: imageDesctipion.statistics,
            registerNotifiers: functionality.registerNotifiers,
            scrollUntill: (i) => extras.scrollTo(i, config),
            pageChange: imageDesctipion.pageChange,
            watchTags: watchTags,
            onExit: imageDesctipion.onExit,
            getCell: (context, idx) => getCell(idx).content(context),
            cellCount: functionality.refreshingStatus.mutation.cellCount,
            download: functionality.download,
            startingCell: startingCell,
            tags: tags,
            onNearEnd: imageDesctipion.ignoreOnNearEnd
                ? null
                : functionality.refreshingStatus.onNearEnd,
          );
        },
      ),
    ).then((value) {
      functionality.selectionGlue.hideNavBar(false);

      return value;
    });
  }

  @override
  State<ImageView> createState() => ImageViewState();
}

class ImageViewState extends State<ImageView>
    with
        ImageViewPageTypeMixin,
        ImageViewPaletteMixin,
        ImageViewLoadingBuilderMixin,
        TickerProviderStateMixin {
  final mainFocus = FocusNode();
  final GlobalKey<ScaffoldState> key = GlobalKey();
  final GlobalKey<WrapImageViewNotifiersState> wrapNotifiersKey = GlobalKey();
  final GlobalKey<WrapImageViewThemeState> wrapThemeKey = GlobalKey();

  late final AnimationController animationController;
  late final DraggableScrollableController bottomSheetController;

  final scrollController = ScrollController();

  late final PageController controller =
      PageController(initialPage: widget.startingCell);

  late final PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug();

  StreamSubscription<int>? _updates;

  late int currentPage = widget.startingCell;
  late int cellCount = widget.cellCount;

  bool refreshing = false;

  int _incr = 0;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);
    bottomSheetController = DraggableScrollableController();

    _updates = widget.updates?.call((c) {
      if (c <= 0) {
        Navigator.of(context).pop();

        return;
      }

      if (cellCount != c) {
        widget.statistics?.viewed();
      }

      cellCount = c;
      final prev = currentPage;
      currentPage = prev.clamp(0, cellCount - 1);

      loadCells(currentPage, cellCount);
      refreshPalette();

      setState(() {});
    });

    widget.statistics?.viewed();

    WakelockPlus.enable();

    loadCells(currentPage, cellCount);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      fullscreenPlug.setTitle(drawCell(currentPage).widgets.alias(false));
      _loadNext(widget.startingCell);
    });

    refreshPalette();
  }

  @override
  void dispose() {
    animationController.dispose();
    bottomSheetController.dispose();
    _updates?.cancel();

    fullscreenPlug.unfullscreen();

    WakelockPlus.disable();
    controller.dispose();

    widget.onExit?.call();

    scrollController.dispose();
    mainFocus.dispose();

    super.dispose();
  }

  void refreshPalette() {
    extractPalette(
      drawCell(currentPage, true),
      key,
      scrollController,
      currentPage,
      _resetAnimation,
    );
  }

  void _resetAnimation() {
    wrapThemeKey.currentState?.resetAnimation();
  }

  void _loadNext(int index) {
    if (index >= cellCount - 3 && !refreshing && widget.onNearEnd != null) {
      setState(() {
        refreshing = true;
      });
      widget.onNearEnd!().then((value) {
        if (context.mounted) {
          setState(() {
            cellCount = value;
          });
        }
      }).onError((error, stackTrace) {
        log(
          "loading next in the image view page",
          level: Level.WARNING.value,
          error: error,
          stackTrace: stackTrace,
        );
      }).then((value) {
        refreshing = false;
      });
    }
  }

  void refreshImage([bool refreshPalette = false]) {
    refreshTries += 1;

    loadCells(currentPage, cellCount);

    final c = drawCell(currentPage, true);
    if (c is NetImage) {
      c.provider.evict();
    } else if (c is NetGif) {
      c.provider.evict();
    }

    if (refreshPalette) {
      this.refreshPalette();
    }

    setState(() {});
  }

  void _onTap() {
    wrapNotifiersKey.currentState?.toggle(fullscreenPlug);
  }

  void _onTagRefresh() {
    try {
      setState(() {});
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    widget.statistics?.viewed();
    widget.statistics?.swiped();

    refreshTries = 0;

    currentPage = index;
    widget.pageChange?.call(this);
    _loadNext(index);

    widget.scrollUntill(index);

    loadCells(index, cellCount);

    final c = drawCell(index);

    fullscreenPlug.setTitle(c.widgets.alias(false));

    refreshPalette();

    setState(() {});
  }

  void _onLongPress() {
    if (widget.download == null) {
      return;
    }

    HapticFeedback.vibrate();
    widget.download!(currentPage);
  }

  void _incrTiles() {
    _incr += 1;

    setState(() {});
  }

  void _onPressedRight() {
    if (currentPage + 1 != cellCount && cellCount != 1) {
      controller.nextPage(duration: 200.ms, curve: Easing.standard);
    } else {
      widget.onRightSwitchPageEnd?.call();
    }
  }

  void _onPressedLeft() {
    if (currentPage != 0 && cellCount != 1) {
      controller.previousPage(duration: 200.ms, curve: Easing.standard);
    } else {
      widget.onLeftSwitchPageEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageViewInfoTilesRefreshNotifier(
      count: _incr,
      incr: _incrTiles,
      child: WrapImageViewNotifiers(
        hardRefresh: refreshImage,
        tags: widget.tags,
        watchTags: widget.watchTags,
        bottomSheetController: bottomSheetController,
        mainFocus: mainFocus,
        controller: animationController,
        gridContext: widget.gridContext,
        key: wrapNotifiersKey,
        onTagRefresh: _onTagRefresh,
        currentCell: drawCell(currentPage),
        registerNotifiers: widget.registerNotifiers,
        child: WrapImageViewTheme(
          key: wrapThemeKey,
          currentPalette: currentPalette,
          previousPallete: previousPallete,
          child: _BottomSheetPopScope(
            controller: bottomSheetController,
            child: WrapImageViewSkeleton(
              scaffoldKey: key,
              scrollController: scrollController,
              bottomSheetController: bottomSheetController,
              controller: animationController,
              currentPalette: currentPalette,
              mainFocus: mainFocus,
              child: ImageViewBody(
                key: ValueKey(refreshTries),
                onPressedLeft: drawCell(currentPage, true) is NetVideo ||
                        drawCell(currentPage, true) is AndroidVideo
                    ? null
                    : _onPressedLeft,
                onPressedRight: _onPressedRight,
                onPageChanged: _onPageChanged,
                onLongPress: _onLongPress,
                pageController: controller,
                loadingBuilder: widget.ignoreLoadingBuilder
                    ? null
                    : (context, event, idx) => loadingBuilder(
                          context,
                          event,
                          idx,
                          currentPage,
                          wrapNotifiersKey,
                          drawCell,
                        ),
                itemCount: cellCount,
                onTap: _onTap,
                builder: galleryBuilder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetPopScope extends StatefulWidget {
  const _BottomSheetPopScope({
    required this.controller,
    required this.child,
  });
  final DraggableScrollableController controller;
  final Widget child;

  @override
  State<_BottomSheetPopScope> createState() => __BottomSheetPopScopeState();
}

class __BottomSheetPopScopeState extends State<_BottomSheetPopScope> {
  bool ignorePointer = false;
  double currentPixels = -1;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);

    super.dispose();
  }

  void listener() {
    if (widget.controller.pixels == currentPixels) {
      return;
    }

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      setState(() {
        currentPixels = widget.controller.pixels;
      });
    });
  }

  void tryScroll(bool _) {
    setState(() {
      ignorePointer = true;
    });

    widget.controller
        .animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Easing.emphasizedAccelerate,
        )
        .then(
          (value) => setState(() {
            ignorePointer = false;
            widget.controller.reset();
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isAttached) {
      return widget.child;
    }

    return PopScope(
      canPop: currentPixels.isNegative &&
          WrapImageViewSkeleton.minPixelsFor(context) != currentPixels,
      onPopInvoked: tryScroll,
      child: IgnorePointer(
        ignoring: ignorePointer,
        child: widget.child,
      ),
    );
  }
}
