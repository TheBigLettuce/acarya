// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'grid.dart';

class _GridBody<T extends Cell> extends StatelessWidget {
  final void Function(BuildContext, int)? download;

  const _GridBody({
    super.key,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio:
              GridMetadataProvider.aspectRatioOf<T>(context).value,
          crossAxisCount: GridMetadataProvider.columnsOf<T>(context).number),
      itemCount: GridElementCountNotifier.of(context),
      itemBuilder: (context, indx) {
        final t1 = DateTime.now();
        final cell = CellProvider.getOf<T>(context, indx);
        print(
            DateTime.now().microsecondsSinceEpoch - t1.microsecondsSinceEpoch);

        return WrappedSelection(
          thisIndx: indx,
          child: GridCell<T>(
            key: cell.uniqueKey(),
            cell: cell,
            indx: indx,
            download: download,
          ),
        );
      },
    );
  }
}
