// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/system_gestures.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';
import '../cell/cell.dart';
import '../keybinds/keybinds.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class PhotoGalleryPageVideoLinux extends StatefulWidget {
  final String url;
  final bool localVideo;

  const PhotoGalleryPageVideoLinux(
      {super.key, required this.url, required this.localVideo});

  @override
  State<PhotoGalleryPageVideoLinux> createState() =>
      _PhotoGalleryPageVideoLinuxState();
}

class _PhotoGalleryPageVideoLinuxState
    extends State<PhotoGalleryPageVideoLinux> {
  Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();

    controller = VideoController(player,
        configuration: const VideoControllerConfiguration(
            enableHardwareAcceleration: false));

    player.open(Media(widget.url));

    //     .then((value) {
    //   controller = value;
    //   player.open(
    //     Media(
    //       widget.url,
    //     ),
    //   );
    //   setState(() {});
    // }).onError((error, stackTrace) {
    //   log("video player linux",
    //       level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    // });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : GestureDetector(
            onDoubleTap: () {
              player.playOrPause();
            },
            child: Video(controller: controller!),
          );
  }
}

class PhotoGalleryPageVideo extends StatefulWidget {
  final String url;
  final bool localVideo;
  const PhotoGalleryPageVideo({
    super.key,
    required this.url,
    required this.localVideo,
  });

  @override
  State<PhotoGalleryPageVideo> createState() => _PhotoGalleryPageVideoState();
}

class _PhotoGalleryPageVideoState extends State<PhotoGalleryPageVideo> {
  late VideoPlayerController controller;
  ChewieController? chewieController;
  bool disposed = false;
  Object? error;

  @override
  void initState() {
    super.initState();

    if (widget.localVideo) {
      controller = VideoPlayerController.contentUri(Uri.parse(widget.url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    } else {
      controller = VideoPlayerController.network(widget.url,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    }

    _initController();
  }

  void _initController() async {
    controller.initialize().then((value) {
      if (!disposed) {
        setState(() {
          chewieController = ChewieController(
              videoPlayerController: controller,
              aspectRatio: controller.value.aspectRatio,
              autoInitialize: false,
              looping: true,
              allowPlaybackSpeedChanging: false,
              showOptions: false,
              showControls: false,
              allowMuting: false,
              zoomAndPan: true,
              showControlsOnInitialize: false,
              autoPlay: false);
        });

        chewieController!.play().onError((e, stackTrace) {
          if (!disposed) {
            setState(() {
              error = e;
            });
          }
        });
      }
    }).onError((e, stackTrace) {
      if (!disposed) {
        setState(() {
          error = e;
        });
      }
    });
  }

  @override
  void dispose() {
    disposed = true;
    controller.dispose();
    if (chewieController != null) {
      chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return error != null
        ? const Icon(Icons.error)
        : chewieController == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : GestureDetector(
                // onTap: widget.onTap,
                onDoubleTap: () {
                  if (!disposed) {
                    if (chewieController!.isPlaying) {
                      chewieController!.pause();
                    } else {
                      chewieController!.play();
                    }
                  }
                },
                child: Chewie(controller: chewieController!),
              );
  }
}

class ImageView<T extends Cell> extends StatefulWidget {
  final int startingCell;
  final T Function(int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final void Function(double? pos, int? selectedCell) updateTagScrollPos;
  final Future<int> Function()? onNearEnd;
  final List<IconButton> Function(ImageViewState<T> state)? addIcons;
  final void Function(int i)? download;
  final double? infoScrollOffset;
  final Color systemOverlayRestoreColor;
  final void Function(ImageViewState<T> state)? pageChange;
  final void Function() onExit;
  final void Function() focusMain;

  const ImageView(
      {super.key,
      required this.updateTagScrollPos,
      required this.cellCount,
      required this.scrollUntill,
      required this.startingCell,
      required this.onExit,
      required this.getCell,
      required this.onNearEnd,
      required this.focusMain,
      required this.systemOverlayRestoreColor,
      this.pageChange,
      this.infoScrollOffset,
      this.download,
      this.addIcons});

  @override
  State<ImageView<T>> createState() => ImageViewState<T>();
}

class ImageViewState<T extends Cell> extends State<ImageView<T>>
    with SingleTickerProviderStateMixin {
  late PageController controller;
  late T currentCell;
  late int currentPage = widget.startingCell;
  late ScrollController scrollController;
  late int cellCount = widget.cellCount;
  bool refreshing = false;

  ImageProvider? fakeProvider;

// TODO: write callbacks for image manipulation

  late AnimationController animationController;
  AnimationController? downloadButtonController;

  final GlobalKey<ScaffoldState> key = GlobalKey();

  PaletteGenerator? currentPalette;

  bool isAppbarShown = true;

  late PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  void _extractPalette() {
    PaletteGenerator.fromImageProvider(currentCell.getCellData(false).thumb)
        .then((value) {
      setState(() {
        currentPalette = value;
      });
    }).onError((error, stackTrace) {
      log("making palette for image_view",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
  }

  void refreshImage() {
    var i = currentCell.fileDisplay();
    if (i is NetImage) {
      PaintingBinding.instance.imageCache.evict(i.provider);
      fakeProvider = MemoryImage(kTransparentImage);

      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {
          fakeProvider = null;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);

    scrollController =
        ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (widget.infoScrollOffset != null) {
        key.currentState?.openEndDrawer();
      }

      fullscreenPlug.setTitle(currentCell.alias(true));
      _loadNext(widget.startingCell);
    });

    currentCell = widget.getCell(widget.startingCell);
    controller = PageController(initialPage: widget.startingCell);

    _extractPalette();
  }

  @override
  void dispose() {
    fullscreenPlug.unFullscreen();

    animationController.dispose();
    widget.updateTagScrollPos(null, null);
    controller.dispose();
    // photoController.dispose();

    widget.onExit();

    super.dispose();
  }

  void _loadNext(int index) {
    if (index >= cellCount - 3 && !refreshing && widget.onNearEnd != null) {
      setState(() {
        refreshing = true;
      });
      widget.onNearEnd!().then((value) {
        if (context.mounted) {
          setState(() {
            refreshing = false;
            cellCount = value;
          });
        }
      }).onError((error, stackTrace) {
        log("loading next in the image view page",
            level: Level.WARNING.value, error: error, stackTrace: stackTrace);
      });
    }
  }

  void _onTap() {
    fullscreenPlug.fullscreen();
    setState(() => isAppbarShown = !isAppbarShown);
  }

  Map<SingleActivatorDescription, Null Function()> _makeBindings(
          BuildContext context) =>
      {
        SingleActivatorDescription(AppLocalizations.of(context)!.back,
            const SingleActivator(LogicalKeyboardKey.escape)): () {
          if (key.currentState?.isEndDrawerOpen ?? false) {
            key.currentState?.closeEndDrawer();
          } else {
            Navigator.pop(context);
          }
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.moveImageRight,
            const SingleActivator(LogicalKeyboardKey.arrowRight,
                shift: true)): () {
          // var pos = photoController.position;
          // photoController.position = pos.translate(-40, 0);
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.moveImageLeft,
            const SingleActivator(LogicalKeyboardKey.arrowLeft,
                shift: true)): () {
          // var pos = photoController.position;
          // photoController.position = pos.translate(40, 0);
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.rotateImageRight,
            const SingleActivator(LogicalKeyboardKey.arrowRight,
                control: true)): () {
          // photoController.rotation += 0.5;
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.rotateImageLeft,
            const SingleActivator(LogicalKeyboardKey.arrowLeft,
                control: true)): () {
          // photoController.rotation -= 0.5;
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.moveImageUp,
            const SingleActivator(LogicalKeyboardKey.arrowUp)): () {
          // var pos = photoController.position;
          // photoController.position = pos.translate(0, 40);
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.moveImageDown,
            const SingleActivator(LogicalKeyboardKey.arrowDown)): () {
          // var pos = photoController.position;
          // photoController.position = pos.translate(0, -40);
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.zoomImageIn,
            const SingleActivator(LogicalKeyboardKey.pageUp)): () {
          // var s = photoController.scale;

          // if (s != null && s < 2.5) {
          // photoController.scale = s + 0.5;
          // }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.zoomImageOut,
            const SingleActivator(LogicalKeyboardKey.pageDown)): () {
          // var s = photoController.scale;

          // if (s != null && s > 0.2) {
          // photoController.scale = s - 0.25;
          // }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.showImageInfo,
            const SingleActivator(LogicalKeyboardKey.keyI)): () {
          if (key.currentState != null) {
            if (key.currentState!.isEndDrawerOpen) {
              key.currentState?.closeEndDrawer();
            } else {
              key.currentState?.openEndDrawer();
            }
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.downloadImage,
            const SingleActivator(LogicalKeyboardKey.keyD)): () {
          if (widget.download != null) {
            widget.download!(currentPage);
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.hideAppBar,
            const SingleActivator(LogicalKeyboardKey.space)): () {
          _onTap();
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.nextImage,
            const SingleActivator(LogicalKeyboardKey.arrowRight)): () {
          controller.nextPage(duration: 500.milliseconds, curve: Curves.linear);
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.previousImage,
            const SingleActivator(LogicalKeyboardKey.arrowLeft)): () {
          controller.previousPage(
              duration: 500.milliseconds, curve: Curves.linear);
        }
      };

  PhotoViewGalleryPageOptions _makeVideo(String uri, bool local) =>
      PhotoViewGalleryPageOptions.customChild(
          disableGestures: true,
          tightMode: true,
          child: Platform.isLinux
              ? PhotoGalleryPageVideoLinux(url: uri, localVideo: local)
              : PhotoGalleryPageVideo(url: uri, localVideo: local));

  PhotoViewGalleryPageOptions _makeNetImage(ImageProvider provider) =>
      PhotoViewGalleryPageOptions(
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 1.8,
          initialScale: PhotoViewComputedScale.contained,
          filterQuality: FilterQuality.high,
          imageProvider: fakeProvider ?? provider);

  PhotoViewGalleryPageOptions _makeAndroidImage(
          Size size, String uri, bool isGif) =>
      PhotoViewGalleryPageOptions.customChild(
          filterQuality: FilterQuality.high,
          disableGestures: true,
          child: Center(
            child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: AspectRatio(
                  aspectRatio: MediaQuery.of(context).size.aspectRatio,
                  child: InteractiveViewer(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: size.aspectRatio,
                        child: AndroidView(
                          viewType: "imageview",
                          hitTestBehavior:
                              PlatformViewHitTestBehavior.transparent,
                          creationParams: {
                            "uri": uri,
                            if (isGif) "gif": "",
                          },
                          creationParamsCodec: const StandardMessageCodec(),
                        ),
                      ),
                    ),
                  ),
                )),
          ));

  @override
  Widget build(BuildContext context) {
    var addB = currentCell.addButtons();
    Map<SingleActivatorDescription, Null Function()> bindings =
        _makeBindings(context);

    var addInfo = currentCell.addInfo(context, () {
      widget.updateTagScrollPos(scrollController.offset, currentPage);
    },
        AddInfoColorData(
          borderColor: Theme.of(context).colorScheme.outlineVariant,
          foregroundColor:
              currentPalette?.mutedColor?.bodyTextColor ?? kListTileColorInInfo,
          systemOverlayColor: widget.systemOverlayRestoreColor,
        ));

    var insets = MediaQuery.viewPaddingOf(context);

    return CallbackShortcuts(
        bindings: {
          ...bindings,
          ...keybindDescription(context, describeKeys(bindings),
              AppLocalizations.of(context)!.imageViewPageName, widget.focusMain)
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
              key: key,
              extendBodyBehindAppBar: true,
              endDrawerEnableOpenDragGesture: false,
              endDrawer: Drawer(
                backgroundColor:
                    currentPalette?.mutedColor?.color.withOpacity(0.5) ??
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    endDrawerHeading(context, "Info", key,
                        titleColor:
                            currentPalette?.dominantColor?.titleTextColor ??
                                Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.5),
                        backroundColor: currentPalette?.dominantColor?.color
                                .withOpacity(0.5) ??
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5)),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: insets.bottom),
                      sliver: SliverList.list(
                          children: [if (addInfo != null) ...addInfo]),
                    )
                  ],
                ),
              ),
              appBar: PreferredSize(
                preferredSize: AppBar().preferredSize,
                child: IgnorePointer(
                  ignoring: !isAppbarShown,
                  child: AppBar(
                    automaticallyImplyLeading: false,
                    foregroundColor:
                        currentPalette?.dominantColor?.bodyTextColor ??
                            kListTileColorInInfo,
                    backgroundColor:
                        currentPalette?.dominantColor?.color.withOpacity(0.5) ??
                            Colors.black.withOpacity(0.5),
                    leading: const BackButton(),
                    title: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(
                            ClipboardData(text: currentCell.alias(false)));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .copiedClipboard)));
                      },
                      child: Text(currentCell.alias(false)),
                    ),
                    actions: [
                      if (addB != null) ...addB,
                      if (widget.addIcons != null)
                        ...widget.addIcons!.call(this),
                      if (widget.download != null)
                        IconButton(
                                onPressed: () {
                                  if (downloadButtonController != null) {
                                    downloadButtonController!.forward(from: 0);
                                  }
                                  widget.download!(currentPage);
                                },
                                icon: const Icon(Icons.download))
                            .animate(
                                onInit: (controller) =>
                                    downloadButtonController = controller,
                                effects: const [ShakeEffect()],
                                autoPlay: false),
                      IconButton(
                          onPressed: () {
                            key.currentState?.openEndDrawer();
                          },
                          icon: const Icon(Icons.info_outline))
                    ],
                  ),
                ).animate(
                  effects: [
                    FadeEffect(begin: 1, end: 0, duration: 500.milliseconds)
                  ],
                  autoPlay: false,
                  target: isAppbarShown ? 0 : 1,
                ),
              ),
              body: gestureDeadZones(context,
                  child: Stack(children: [
                    GestureDetector(
                      onLongPress: widget.download == null
                          ? null
                          : () {
                              HapticFeedback.vibrate();
                              widget.download!(currentPage);
                            },
                      onTap: _onTap,
                      child: PhotoViewGallery.builder(
                          loadingBuilder: (context, event) {
                            final expectedBytes = event?.expectedTotalBytes;
                            final loadedBytes = event?.cumulativeBytesLoaded;
                            final value =
                                loadedBytes != null && expectedBytes != null
                                    ? loadedBytes / expectedBytes
                                    : null;

                            return Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                    ColorTween(
                                            begin: Colors.black,
                                            end: currentPalette
                                                ?.mutedColor?.color
                                                .withOpacity(0.7))
                                        .lerp(value ?? 0)!,
                                    ColorTween(
                                            begin: Colors.black38,
                                            end: currentPalette
                                                ?.mutedColor?.color
                                                .withOpacity(0.5))
                                        .lerp(value ?? 0)!,
                                    ColorTween(
                                            begin: Colors.black12,
                                            end: currentPalette
                                                ?.mutedColor?.color
                                                .withOpacity(0.3))
                                        .lerp(value ?? 0)!,
                                  ])),
                              child: Center(
                                child: SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: CircularProgressIndicator(
                                        color: currentPalette
                                            ?.dominantColor?.color,
                                        value: value)),
                              ),
                            );
                          },
                          enableRotation: true,
                          backgroundDecoration: BoxDecoration(
                              color: currentPalette?.mutedColor?.color
                                  .withOpacity(0.7)),
                          onPageChanged: (index) async {
                            currentPage = index;
                            widget.pageChange?.call(this);
                            _loadNext(index);

                            widget.scrollUntill(index);

                            var c = widget.getCell(index);

                            fullscreenPlug.setTitle(c.alias(true));

                            setState(() {
                              currentCell = c;
                              _extractPalette();
                            });
                          },
                          pageController: controller,
                          itemCount: cellCount,
                          builder: (context, indx) {
                            var fileContent =
                                widget.getCell(indx).fileDisplay();

                            return switch (fileContent) {
                              AndroidImage() => _makeAndroidImage(
                                  fileContent.size, fileContent.uri, false),
                              AndroidGif() => _makeAndroidImage(
                                  fileContent.size, fileContent.uri, true),
                              NetGif() => _makeNetImage(fileContent.provider),
                              NetImage() => _makeNetImage(fileContent.provider),
                              AndroidVideo() =>
                                _makeVideo(fileContent.uri, true),
                              NetVideo() => _makeVideo(fileContent.uri, false),
                              EmptyContent() =>
                                PhotoViewGalleryPageOptions.customChild(
                                    child: const Center(
                                  child: Icon(Icons.error_outline),
                                ))
                            };
                          }),
                    ),
                  ]),
                  left: true,
                  right: true)),
        ));
  }
}