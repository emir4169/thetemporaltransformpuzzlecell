import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:the_puzzle_cell/utils/ScaleAssist.dart';

class LoadingDialog extends StatefulWidget {
  final Future<dynamic> future;
  final String title;
  final String? completionMessage;

  const LoadingDialog({Key? key, required this.future, required this.title, this.completionMessage}) : super(key: key);

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 30.w,
        height: 20.h,
        child: Center(
          child: FutureBuilder(
            future: widget.future,
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Text(snap.error!.toString());
              }

              if (snap.hasData) {
                if (widget.completionMessage == null) {
                  Navigator.pop(ctx);
                  return Text("");
                } else {
                  return SingleChildScrollView(child: Text(widget.completionMessage!.replaceAll("%value", snap.data.toString()), style: TextStyle(fontSize: 7.sp)));
                }
              }

              return CircularProgressIndicator.adaptive();
            },
          ),
        ),
      ),
    );
  }
}
