// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_description.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/page_switching_widget.dart";

typedef WatchFire<T> = StreamSubscription<T> Function(
  void Function(T), [
  bool fire,
]);

class PageIcon {
  const PageIcon(
    this.icon, {
    this.watchCount,
  });

  final IconData icon;
  final WatchFire<int>? watchCount;
}

class PageToaggable {
  const PageToaggable(
    this.icon, {
    this.active = true,
  });

  final IconData icon;
  final bool active;
}

class PageLabel {
  const PageLabel(
    this.label, {
    this.count = -1,
  });

  final String label;
  final int count;
}

sealed class PageSwitcherInterface<T extends CellBase> {
  PageDescription Function(BuildContext context, GridFrameState<T> state, int i)
      get buildPage;

  Widget switcherWidget(BuildContext context, GridFrameState<T> state);
}

class PageSwitcherToggable<T extends CellBase>
    implements PageSwitcherInterface<T> {
  const PageSwitcherToggable(
    this.pages,
    this.toggle, {
    required this.stateKey,
  });

  final List<PageToaggable> pages;

  final bool Function(BuildContext context, int i) toggle;

  final GlobalKey<ToggableLabelSwitcherWidgetState> stateKey;

  @override
  PageDescription Function(
    BuildContext context,
    GridFrameState<T> state,
    // ignore: prefer_function_declarations_over_variables
    int i,
  ) get buildPage => _noWidget;

  PageDescription _noWidget(
    BuildContext context,
    GridFrameState<T> state,
    int i,
  ) {
    return const PageDescription(
      slivers: [SliverPadding(padding: EdgeInsets.zero)],
    );
  }

  @override
  Widget switcherWidget(BuildContext context, GridFrameState<T> state) =>
      ToggableLabelSwitcherWidget<T>(
        key: stateKey,
        pages: pages,
        toggle: toggle,
      );
}

class ToggableLabelSwitcherWidget<T extends CellBase> extends StatefulWidget {
  const ToggableLabelSwitcherWidget({
    super.key,
    required this.pages,
    required this.toggle,
  });
  final List<PageToaggable> pages;
  final bool Function(BuildContext, int) toggle;

  @override
  State<ToggableLabelSwitcherWidget> createState() =>
      ToggableLabelSwitcherWidgetState();
}

class ToggableLabelSwitcherWidgetState
    extends State<ToggableLabelSwitcherWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  int currentPage = 0;

  void setPage(int p) {
    setState(() {
      currentPage = p;
    });
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      value: 1,
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    final gestureInsets = MediaQuery.systemGestureInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 8 + gestureInsets.left * 0.5,
        right: 8 + gestureInsets.right * 0.5,
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: pages.indexed.map((value) {
            final (idx, label) = value;

            return IconButton.filled(
              isSelected: idx + 1 == currentPage,
              onPressed: !label.active
                  ? null
                  : idx + 1 == currentPage
                      ? () {
                          widget.toggle(context, 0);

                          setState(() {
                            currentPage = 0;
                          });
                        }
                      : () {
                          controller.reverse().then((value) {
                            if (widget.toggle(context, idx + 1)) {
                              setState(() {
                                currentPage = idx + 1;
                              });
                            }

                            controller.value = 1;
                          });
                        },
              icon: Icon(label.icon),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PageSwitcherLabel<T extends CellBase>
    implements PageSwitcherInterface<T> {
  const PageSwitcherLabel(this.pages, this.buildPage);

  final List<PageLabel> pages;

  @override
  final PageDescription Function(
    BuildContext context,
    GridFrameState<T> state,
    int i,
  ) buildPage;

  @override
  Widget switcherWidget(BuildContext context, GridFrameState<T> state) =>
      LabelSwitcherWidget<T>(
        pages: pages,
        currentPage: state.currentPageF,
        switchPage: state.switchPage,
      );
}

class LabelSwitcherWidget<T extends CellBase> extends StatefulWidget {
  const LabelSwitcherWidget({
    super.key,
    required this.pages,
    required this.currentPage,
    required this.switchPage,
    this.sliver = false,
    this.noHorizontalPadding = false,
  });
  final List<PageLabel> pages;
  final void Function(int) switchPage;
  final int Function() currentPage;
  final bool noHorizontalPadding;
  final bool sliver;

  @override
  State<LabelSwitcherWidget> createState() => _LabelSwitcherWidgetState();
}

class _LabelSwitcherWidgetState extends State<LabelSwitcherWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      value: 1,
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    final currentPage = widget.currentPage();

    final child = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: pages.indexed.map((value) {
          final (idx, label) = value;

          return Padding(
            padding: const EdgeInsets.only(right: 8) +
                (widget.noHorizontalPadding
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(top: 40)),
            child: GestureDetector(
              onTap: idx == currentPage
                  ? null
                  : () {
                      controller.reverse().then((value) {
                        widget.switchPage(idx);

                        controller.value = 1;
                      });
                    },
              child: _Label(
                count: label.count,
                text: label.label,
                isSelected: idx == currentPage,
                controller: controller,
              ),
            ),
          );
        }).toList(),
      ),
    );

    final padding = widget.noHorizontalPadding
        ? const EdgeInsets.only(
            top: 24 / 2,
            bottom: 24 / 2,
          )
        : const EdgeInsets.only(
            top: 24 / 2,
            bottom: 24 / 2,
            right: 24,
            left: 24,
          );

    return widget.sliver
        ? SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: child,
            ),
          )
        : Padding(
            padding: padding,
            child: child,
          );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.isSelected,
    required this.controller,
    required this.count,
  });
  final String text;
  final bool isSelected;
  final int count;
  final AnimationController controller;

  static final colorOpacityTween = Tween<double>(begin: 0.4, end: 0.8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleText = theme.textTheme.headlineMedium?.copyWith(
      shadows: [
        Shadow(
          color: theme.colorScheme.primary.withOpacity(0.2),
          blurRadius: isSelected ? 0.4 : 0.2,
        ),
      ],
      fontWeight: FontWeight.w600,
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(
              colorOpacityTween
                  .transform(Easing.standard.transform(controller.value)),
            )
          : theme.colorScheme.onSurface.withOpacity(0.5),
    );

    return count.isNegative
        ? Text(
            text,
            style: styleText,
          )
        : RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: text,
                  style: styleText,
                ),
                TextSpan(
                  text: " $count",
                  style: styleText?.copyWith(
                    fontSize: theme.textTheme.titleMedium?.fontSize,
                    color: styleText.color
                        ?.withOpacity(styleText.color!.opacity - 0.2),
                  ),
                ),
              ],
            ),
          );
  }
}

class PageSwitcherIcons<T extends CellBase>
    implements PageSwitcherInterface<T> {
  const PageSwitcherIcons(
    this.pages,
    this.buildPage, {
    this.overrideHomeIcon,
  });

  final Icon? overrideHomeIcon;
  final List<PageIcon> pages;

  @override
  final PageDescription Function(
    BuildContext context,
    GridFrameState<T> state,
    int i,
  ) buildPage;

  @override
  Widget switcherWidget(BuildContext context, GridFrameState<T> state) =>
      PageSwitchingIconsWidget(
        controller: state.controller,
        selection: state.selection,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        state: state,
        pageSwitcher: this,
      );
}
