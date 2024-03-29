// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';

class UnsizedCard extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final String tooltip;
  final ImageProvider? backgroundImage;
  final bool transparentBackground;
  final void Function()? onPressed;
  final void Function()? onLongPressed;
  final bool leanToLeft;

  const UnsizedCard({
    super.key,
    required this.subtitle,
    required this.title,
    this.backgroundImage,
    required this.tooltip,
    this.transparentBackground = false,
    this.onPressed,
    this.leanToLeft = true,
    this.onLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onLongPressed: onLongPressed,
      subtitle: subtitle,
      title: title,
      backgroundImage: backgroundImage,
      tooltip: tooltip,
      transparentBackground: transparentBackground,
      onPressed: onPressed,
      width: null,
      height: null,
      leanLeft: leanToLeft,
    );
  }
}

class BaseCard extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final ImageProvider? backgroundImage;
  final String tooltip;
  final bool transparentBackground;
  final void Function()? onPressed;
  final double? width;
  final double? height;
  final bool expandTitle;
  final void Function()? onLongPressed;
  final bool leanLeft;

  const BaseCard({
    super.key,
    this.backgroundImage,
    required this.subtitle,
    required this.title,
    required this.tooltip,
    this.height = 80,
    this.width = 100,
    this.expandTitle = false,
    this.transparentBackground = false,
    this.onPressed,
    this.onLongPressed,
    this.leanLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget body() => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: leanLeft
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  DefaultTextStyle.merge(
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: DefaultTextStyle.of(context).style.color ??
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                        letterSpacing: 0.8),
                    child: Padding(
                      padding: height == null
                          ? EdgeInsets.zero
                          : EdgeInsets.only(
                              left: leanLeft ? 0 : 4,
                              right: leanLeft ? 24 : 8,
                              top: 4,
                              bottom: 4),
                      child: expandTitle ? Expanded(child: title) : title,
                    ),
                  ),
                  if (constraints.maxWidth > 50)
                    DefaultTextStyle.merge(
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: leanLeft ? 0 : 8, right: leanLeft ? 24 : 8),
                        child: subtitle,
                      ),
                    ),
                ],
              ),
            );

        Widget card() => InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onPressed,
              onLongPress: onLongPressed,
              splashColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              child: Card.filled(
                clipBehavior: Clip.antiAlias,
                color: transparentBackground || backgroundImage != null
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0)
                    : null,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      if (backgroundImage != null)
                        BackgroundImageBase(image: backgroundImage!),
                      body(),
                    ],
                  ),
                ),
              ),
            );

        return constraints.maxWidth > 50
            ? card()
            : Tooltip(
                message: tooltip,
                child: card(),
              );
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const DashboardCard({super.key, required this.subtitle, required this.title});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      tooltip: subtitle,
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.center,
      ),
      title: Text(
        title,
      ),
    );
  }
}
