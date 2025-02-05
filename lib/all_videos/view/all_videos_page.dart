
import 'dart:io';

import 'package:air_controller/ext/pointer_down_event_x.dart';
import 'package:air_controller/ext/string-ext.dart';
import 'package:air_controller/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../constant.dart';
import '../../model/video_item.dart';
import '../../model/video_order_type.dart';
import '../../network/device_connection_manager.dart';
import '../../repository/file_repository.dart';
import '../../repository/video_repository.dart';
import '../../util/common_util.dart';
import '../../util/system_app_launcher.dart';
import '../../video_home/bloc/video_home_bloc.dart';
import '../../widget/overlay_menu_item.dart';
import '../../widget/progress_indictor_dialog.dart';
import '../../widget/video_flow_widget.dart';
import '../bloc/all_videos_bloc.dart';

class AllVideosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllVideosBloc>(
        create: (context) => AllVideosBloc(
          fileRepository: context.read<FileRepository>(),
          videoRepository: context.read<VideoRepository>()
        )..add(AllVideosSubscriptionRequested()),
      child: AllVideosView(),
    );
  }

}

class AllVideosView extends StatelessWidget {
  FocusNode? _rootFocusNode = null;
  bool _isControlPressed = false;
  bool _isShiftPressed = false;

  ProgressIndicatorDialog? _progressIndicatorDialog;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xff85a8d0);
    const spinKit = SpinKitCircle(color: color, size: 60.0);

    _rootFocusNode = FocusNode();
    _rootFocusNode?.canRequestFocus = true;
    _rootFocusNode?.requestFocus();

    AllVideosStatus status = context.select((AllVideosBloc bloc) => bloc.state.status);
    List<VideoItem> videos = context.select((AllVideosBloc bloc) => bloc.state.videos);
    List<VideoItem> checkedVideos = context.select((AllVideosBloc bloc) => bloc.state.checkedVideos);
    VideoOrderType orderType = context.select((VideoHomeBloc bloc) => bloc.state.orderType);

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<AllVideosBloc, AllVideosState>(
            listener: (context, state) {
              VideoHomeTab currentTab = context.read<VideoHomeBloc>().state.tab;

              if (currentTab == VideoHomeTab.allVideos) {
                context.read<VideoHomeBloc>().add(VideoHomeItemCountChanged(
                    VideoHomeItemCount(
                        state.videos.length, state.checkedVideos.length)
                ));

                context.read<VideoHomeBloc>().add(VideoHomeDeleteStatusChanged(
                    state.checkedVideos.length > 0
                ));
              }
            },
            listenWhen: (previous, current) => previous.videos.length != current.videos.length
                || previous.checkedVideos.length != current.checkedVideos.length
          ),

          BlocListener<AllVideosBloc, AllVideosState>(
              listener: (context, state) {
                _openMenu(
                    pageContext: context,
                    position: state.openMenuStatus.position!,
                    videos: state.videos,
                    checkedVideos: state.checkedVideos,
                    current: state.openMenuStatus.target
                );
              },
              listenWhen: (previous, current) => previous.openMenuStatus != current.openMenuStatus
                  && current.openMenuStatus.isOpened
          ),

          BlocListener<AllVideosBloc, AllVideosState>(
              listener: (context, state) {
                if (state.deleteStatus.status == AllVideosDeleteStatus.loading) {
                  SmartDialog.showLoading();
                }
                
                if (state.deleteStatus.status == AllVideosDeleteStatus.failure) {
                  SmartDialog.dismiss();

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                        SnackBar(content: Text(
                          state.deleteStatus.failureReason ?? "Delete videos failure."
                        )
                      )
                    );
                }
                
                if (state.deleteStatus.status == AllVideosDeleteStatus.success) {
                  SmartDialog.dismiss();
                }
              },
              listenWhen: (previous, current) => previous.deleteStatus != current.deleteStatus
                  && current.deleteStatus.status != AllVideosDeleteStatus.initial
          ),

          BlocListener<AllVideosBloc, AllVideosState>(
            listener: (context, state) {
              if (state.copyStatus.status == AllVideosCopyStatus.start) {
                _showDownloadProgressDialog(context, state.checkedVideos);
              }

              if (state.copyStatus.status == AllVideosCopyStatus.copying) {
                if (_progressIndicatorDialog?.isShowing == true) {
                  int current = state.copyStatus.current;
                  int total = state.copyStatus.total;

                  if (current > 0) {
                    String title = context.l10n.exporting;

                    List<VideoItem> checkedVideos = state.checkedVideos;

                    if (checkedVideos.length == 1) {
                      String name = checkedVideos.single.name;

                      title = context.l10n.placeholderExporting.replaceFirst(
                          "%s", name);
                    }

                    if (checkedVideos.length > 1) {
                      String itemStr = context.l10n.placeHolderItemCount03.replaceFirst("%d",
                          "${checkedVideos.length}");
                      title = context.l10n.placeholderExporting.replaceFirst("%s", itemStr);
                    }

                    _progressIndicatorDialog?.title = title;
                  }

                  _progressIndicatorDialog?.subtitle =
                  "${CommonUtil.convertToReadableSize(current)}/${CommonUtil
                      .convertToReadableSize(total)}";
                  _progressIndicatorDialog?.updateProgress(current / total);
                }
              }

              if (state.copyStatus.status == AllVideosCopyStatus.failure) {
                _progressIndicatorDialog?.dismiss();

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(
                      state.copyStatus.error ?? context.l10n.copyFileFailure
                  )));
              }

              if (state.copyStatus.status == AllVideosCopyStatus.success) {
                _progressIndicatorDialog?.dismiss();
              }
            },
            listenWhen: (previous, current) =>
            previous.copyStatus != current.copyStatus
                && current.copyStatus.status != AllVideosCopyStatus.initial,
          ),

          BlocListener<VideoHomeBloc, VideoHomeState>(
              listener: (context, state) {
                context.read<VideoHomeBloc>().add(VideoHomeOderTypeVisibilityChanged(true));
                context.read<VideoHomeBloc>().add(VideoHomeBackVisibilityChanged(false));

                List<VideoItem> videos = context.read<AllVideosBloc>().state.videos;
                List<VideoItem> checkedVideos = context.read<AllVideosBloc>().state.checkedVideos;

                context.read<VideoHomeBloc>().add(VideoHomeItemCountChanged(
                    VideoHomeItemCount(videos.length, checkedVideos.length)
                ));
                context.read<VideoHomeBloc>().add(VideoHomeDeleteStatusChanged(checkedVideos.length > 0));
              },
              listenWhen: (previous, current)
              => previous.tab != current.tab && current.tab == VideoHomeTab.allVideos
          ),

          BlocListener<VideoHomeBloc, VideoHomeState>(
              listener: (context, state) {
                if (state.tab == VideoHomeTab.allVideos) {
                  _tryToDeleteVideos(context, context.read<AllVideosBloc>().state.checkedVideos);
                }
              },
              listenWhen: (previous, current)
              => previous.deleteTapStatus != current.deleteTapStatus
                  && current.deleteTapStatus == VideoHomeDeleteTapStatus.tap
          ),
        ],
        child: Stack(
          children: [
            Focus(
                autofocus: true,
                focusNode: _rootFocusNode,
                child: VideoFlowWidget(
                  rootUrl: "http://${DeviceConnectionManager.instance.currentDevice?.ip}:${Constant.PORT_HTTP}",
                  sortOrder: orderType,
                  videos: videos,
                  selectedVideos: checkedVideos,
                  onVisibleChange: (isTotalVisible, isPartOfVisible) {

                  },
                  onPointerDown: (event, video) {
                    if (event.isRightMouseClick()) {
                      List<VideoItem> checkedVideos = context.read<AllVideosBloc>().state.checkedVideos;

                      if (!checkedVideos.contains(video)) {
                        context.read<AllVideosBloc>().add(AllVideosCheckedChanged(video));
                      }

                      context.read<AllVideosBloc>().add(AllVideosOpenMenuStatusChanged(
                          AllVideosOpenMenuStatus(
                            isOpened: true,
                            position: event.position,
                            target: video
                          )
                      ));
                    }
                  },
                  onVideoTap: (video) {
                    context.read<AllVideosBloc>().add(AllVideosCheckedChanged(video));
                  },
                  onVideoDoubleTap: (video) {
                    context.read<AllVideosBloc>().add(AllVideosCheckedChanged(video));

                    SystemAppLauncher.openVideo(video);
                  },
                  onOutsideTap: () {
                    context.read<AllVideosBloc>().add(AllVideosClearChecked());
                  },
                ),
                onKey: (node, event) {
                  _isControlPressed = Platform.isMacOS
                      ? event.isMetaPressed
                      : event.isControlPressed;
                  _isShiftPressed = event.isShiftPressed;

                  AllVideosBoardKeyStatus status = AllVideosBoardKeyStatus.none;

                  if (_isControlPressed) {
                    status = AllVideosBoardKeyStatus.ctrlDown;
                  } else if (_isShiftPressed) {
                    status = AllVideosBoardKeyStatus.shiftDown;
                  }

                  context.read<AllVideosBloc>().add(AllVideosKeyStatusChanged(status));

                  if (Platform.isMacOS) {
                    if (event.isMetaPressed &&
                        event.isKeyPressed(LogicalKeyboardKey.keyA)) {
                      context.read<AllVideosBloc>().add(AllVideosCheckAll());
                      return KeyEventResult.handled;
                    }
                  } else {
                    if (event.isControlPressed &&
                        event.isKeyPressed(LogicalKeyboardKey.keyA)) {
                      context.read<AllVideosBloc>().add(AllVideosCheckAll());
                      return KeyEventResult.handled;
                    }
                  }

                  return KeyEventResult.ignored;
                }),
            Visibility(
              child: Container(child: spinKit, color: Colors.white),
              maintainSize: false,
              visible: status == AllVideosStatus.loading,
            )
          ],
        ),
      ),
    );
  }

  void _openMenu(
      {required BuildContext pageContext,
        required Offset position,
        required List<VideoItem> videos,
        required List<VideoItem> checkedVideos,
        required VideoItem current}) {
    String copyTitle = "";

    if (checkedVideos.length == 1) {
      VideoItem videoItem = checkedVideos.single;

      String name = videoItem.name;

      copyTitle = pageContext.l10n.placeHolderCopyToComputer.replaceFirst("%s", name)
          .adaptForOverflow();
    } else {
      String itemStr = pageContext.l10n.placeHolderItemCount03.replaceFirst("%d", "${checkedVideos.length}");
      copyTitle = pageContext.l10n.placeHolderCopyToComputer.replaceFirst("%s", itemStr)
          .adaptForOverflow();
    }

    double width = 320;
    double itemHeight = 25;
    EdgeInsets itemPadding = EdgeInsets.only(left: 8, right: 8);
    EdgeInsets itemMargin = EdgeInsets.only(top: 6, bottom: 6);
    BorderRadius itemBorderRadius = BorderRadius.all(Radius.circular(3));
    Color defaultItemBgColor = Color(0xffd8d5d3);
    Divider divider = Divider(
        height: 1,
        thickness: 1,
        indent: 6,
        endIndent: 6,
        color: Color(0xffbabebf));

    showDialog(
        context: pageContext,
        barrierColor: Colors.transparent,
        builder: (dialogContext) {
          return Stack(
            children: [
              Positioned(
                  child: Container(
                    child: Column(
                      children: [
                        OverlayMenuItem(
                          width: width,
                          height: itemHeight,
                          padding: itemPadding,
                          margin: itemMargin,
                          borderRadius: itemBorderRadius,
                          defaultBackgroundColor: defaultItemBgColor,
                          title: pageContext.l10n.open,
                          onTap: () {
                            Navigator.of(dialogContext).pop();

                            SystemAppLauncher.openVideo(current);
                          },
                        ),
                        divider,
                        OverlayMenuItem(
                          width: width,
                          height: itemHeight,
                          padding: itemPadding,
                          margin: itemMargin,
                          borderRadius: itemBorderRadius,
                          defaultBackgroundColor: defaultItemBgColor,
                          title: copyTitle,
                          onTap: () {
                            Navigator.of(dialogContext).pop();

                            CommonUtil.openFilePicker(
                                pageContext.l10n.chooseDir, (dir) {
                              _startCopy(pageContext, checkedVideos, dir);
                            }, (error) {
                              debugPrint("_openFilePicker, error: $error");
                            });
                          },
                        ),
                        divider,
                        OverlayMenuItem(
                          width: width,
                          height: itemHeight,
                          padding: itemPadding,
                          margin: itemMargin,
                          borderRadius: itemBorderRadius,
                          defaultBackgroundColor: defaultItemBgColor,
                          title: pageContext.l10n.delete,
                          onTap: () {
                            Navigator.of(dialogContext).pop();

                            _tryToDeleteVideos(pageContext, checkedVideos);
                          },
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                        color: Color(0xffd8d5d3),
                        borderRadius: BorderRadius.all(Radius.circular(6))),
                    padding: EdgeInsets.all(5),
                  ),
                  left: position.dx,
                  top: position.dy,
                  width: width)
            ],
          );
        });
  }

  void _showDownloadProgressDialog(BuildContext context, List<VideoItem> videos) {
    if (null == _progressIndicatorDialog) {
      _progressIndicatorDialog = ProgressIndicatorDialog(context: context);
      _progressIndicatorDialog?.onCancelClick(() {
        _progressIndicatorDialog?.dismiss();
        context.read<AllVideosBloc>().add(AllVideosCancelCopy());
      });
    }

    String title = context.l10n.preparing;

    if (videos.length > 1) {
      title = context.l10n.compressing;
    }

    _progressIndicatorDialog?.title = title;

    if (!_progressIndicatorDialog!.isShowing) {
      _progressIndicatorDialog!.show();
    }
  }

  void _startCopy(BuildContext context, List<VideoItem> checkedVideos, String dir) {
    context.read<AllVideosBloc>().add(AllVideosCopySubmitted(checkedVideos, dir));
  }

  void _tryToDeleteVideos(BuildContext pageContext, List<VideoItem> checkedVideos) {
    CommonUtil.showConfirmDialog(
        pageContext,
        "${pageContext.l10n.tipDeleteTitle.replaceFirst("%s", "${checkedVideos.length}")}",
        pageContext.l10n.tipDeleteDesc, pageContext.l10n.cancel, pageContext.l10n.delete,
            (context) {
          Navigator.of(context, rootNavigator: true).pop();

          pageContext.read<AllVideosBloc>().add(AllVideosDeleteSubmitted(checkedVideos));
        }, (context) {
      Navigator.of(context, rootNavigator: true).pop();
    });
  }
}