import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../notifiers/tag_manager.dart';

class SearchLaunchGrid1 extends StatefulWidget {
  final Booru booru;
  final Future<List<String>> Function(String) complF;
  final String? hint;

  const SearchLaunchGrid1(
      {super.key, required this.booru, required this.complF, this.hint});

  @override
  State<SearchLaunchGrid1> createState() => _SearchLaunchGrid1State();
}

class _SearchLaunchGrid1State extends State<SearchLaunchGrid1> {
  final controller = TextEditingController();
  final focus = FocusNode();
  String? currentlyHighlightedTag;

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutocompleteWidget(
        controller,
        (s) {
          currentlyHighlightedTag = s;
        },
        (s) => TagManagerNotifier.of(context)
            .onTagPressed(context, s, widget.booru, false),
        () {
          // => _state.mainFocus.requestFocus(),
        },
        widget.complF,
        focus,
        ignoreFocusNotifier: true,
        scrollHack: _ScrollHack(),
        customHint:
            "${AppLocalizations.of(context)!.searchHint} ${widget.hint?.toLowerCase() ?? ''}");
  }
}

// class SearchLaunchGrid extends StatelessWidget {
//   final Booru booru;

//   const SearchLaunchGrid({super.key, required this.booru});

//   @override
//   Widget build(BuildContext context) {
//     return AutocompleteWidget(searchTextController, (s) {
//       currentlyHighlightedTag = s;
//     },
//         (s) => TagManagerNotifier.of(context)
//             .onTagPressed(context, s, booru, _state.restorable),
//         () => _state.mainFocus.requestFocus(),
//         BooruAPINotifier.of(context).completeTag,
//         searchFocus,
//         scrollHack: _scrollHack,
//         showSearch: !Platform.isAndroid,
//         roundBorders: false,
//         ignoreFocusNotifier: Platform.isAndroid,
//         addItems: _state.addItems,
//         customHint:
//             "${AppLocalizations.of(context)!.searchHint} ${hint?.toLowerCase() ?? ''}");
//   }
// }

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
