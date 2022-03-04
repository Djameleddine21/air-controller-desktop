
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widget/confirm_dialog_builder.dart';

class CommonUtil {
  static final _KB_BOUND = 1 * 1024;
  static final _MB_BOUND = 1 * 1024 * 1024;
  static final _GB_BOUND = 1 * 1024 * 1024 * 1024;

  static final _ONE_HOUR = 60 * 60 * 1000;
  static final _ONE_MINUTE = 60 * 1000;
  static final _ONE_SECOND = 1000;

  static String convertToReadableSize(int size) {
    if (size < _KB_BOUND) {
      return "${size} bytes";
    }
    if (size >= _KB_BOUND && size < _MB_BOUND) {
      return "${(size / 1024).toStringAsFixed(1)} KB";
    }

    if (size >= _MB_BOUND && size <= _GB_BOUND) {
      return "${(size / 1024 / 1024).toStringAsFixed(1)} MB";
    }

    return "${(size / 1024 / 1024 / 1024).toStringAsFixed(1)} GB";
  }

  static String formatTime(int time, String pattern) {
    final df = DateFormat(pattern);
    return df.format(new DateTime.fromMillisecondsSinceEpoch(time));
  }

  static void showConfirmDialog(
      BuildContext context,
      String content,
      String desc,
      String negativeText,
      String positiveText,
      Function(BuildContext context) onPositiveClick,
      Function(BuildContext context) onNegativeClick) {
    Dialog dialog = ConfirmDialogBuilder()
        .content(content)
        .desc(desc)
        .negativeBtnText(negativeText)
        .positiveBtnText(positiveText)
        .onPositiveClick(onPositiveClick)
        .onNegativeClick(onNegativeClick)
        .build();

    showDialog(
        context: context,
        builder: (context) {
          return dialog;
        },
        barrierDismissible: false);
  }

  static void openFilePicker(String title, void onSuccess(String dir), void onError(String error)) {
    FilePicker.platform.getDirectoryPath(dialogTitle: title, lockParentWindow: true)
        .then((value) {
      if (null == value) {
        onError.call("Dir is null");
      } else {
        onSuccess.call(value);
      }
    }).catchError((error) {
      onError.call(error.toString());
    });
  }

  static String convertToReadableDuration(int duration) {
    if (duration >= _ONE_HOUR) {
      int hour = (duration / _ONE_HOUR).truncate();

      String durStr = "${hour}小时";

      if (duration - hour * _ONE_HOUR > 0) {
        int min = ((duration - hour * _ONE_HOUR) / _ONE_MINUTE).truncate();

        durStr = "${durStr}${min}分";

        if (duration - hour * _ONE_HOUR - min * _ONE_MINUTE > 0) {
          int sec =
          ((duration - hour * _ONE_HOUR - min * _ONE_MINUTE) / _ONE_SECOND)
              .truncate();

          durStr = "${durStr}${sec}秒";
        }
      }

      return durStr;
    } else if (duration < _ONE_HOUR && duration >= _ONE_MINUTE) {
      int min = (duration / _ONE_MINUTE).truncate();

      String durStr = "${min}分";

      if (duration - min * _ONE_MINUTE > 0) {
        int sec = ((duration - min * _ONE_MINUTE) / _ONE_SECOND).truncate();

        durStr = "${durStr}${sec}秒";
      }

      return durStr;
    } else {
      int sec = (duration / _ONE_SECOND).truncate();

      return "${sec}秒";
    }
  }
}