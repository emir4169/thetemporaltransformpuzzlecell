import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:the_puzzle_cell/layout/layout.dart';
import 'package:the_puzzle_cell/utils/ScaleAssist.dart';
import 'package:the_puzzle_cell/logic/logic.dart';

class SeeOnlineDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SeeOnlineDialogState();
}

class _SeeOnlineDialogState extends State<SeeOnlineDialog> {
  @override
  Widget build(BuildContext context) {
    final online = game.cursors.keys.toList();

    return ContentDialog(
      title: Text(lang("see-online-btn.title", "See Online")),
      content: SizedBox(
        height: 30.h,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: ListView.builder(
                itemCount: online.length,
                padding: EdgeInsets.symmetric(vertical: 0.7.h, horizontal: 0.7.w),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: constraints.maxWidth * 0.8,
                    child: ListTile(
                      title: Text(online[index]),
                      tileColor: ConstantColorButtonState(Colors.grey[130]),
                      onPressed: () {},
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}