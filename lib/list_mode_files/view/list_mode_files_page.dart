
import 'package:air_controller/ext/pointer_down_event_x.dart';
import 'package:air_controller/l10n/l10n.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../file_home/bloc/file_home_bloc.dart';
import '../../model/file_item.dart';
import '../../model/file_node.dart';
import '../../util/common_util.dart';
import '../../util/system_app_launcher.dart';

class ListModeFilesPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FileHomeBloc>(
        create: (context) => context.read<FileHomeBloc>(),
      child: ListModeFilesView(),
    );
  }
}

class ListModeFilesView extends StatelessWidget {
  final _INDENT_STEP = 10.0;

  @override
  Widget build(BuildContext context) {
    TextStyle headerStyle =
    TextStyle(fontSize: 14, color: Colors.black);

    List<FileNode> files = context.select((FileHomeBloc bloc) => bloc.state.files);
    List<FileNode> checkedFiles = context.select((FileHomeBloc bloc) => bloc.state.checkedFiles);
    FileNode? currentRenamingFile = context.select((FileHomeBloc bloc) => bloc.state.currentRenamingFile);
    bool isRenamingMode = context.select((FileHomeBloc bloc) => bloc.state.isRenamingMode);
    FileHomeSortColumn sortColumn = context.select((FileHomeBloc bloc) => bloc.state.sortColumn);
    FileHomeSortDirection sortDirection = context.select((FileHomeBloc bloc) => bloc.state.sortDirection);
    FileNode? currentDir = context.select((FileHomeBloc bloc) => bloc.state.currentDir);
    bool isRootDir = context.select((FileHomeBloc bloc) => bloc.state.isRootDir);

    Visibility getRightArrowIcon(int index, FileNode node) {
      String iconPath = "";

      if (checkedFiles.contains(node)) {
        if (node.isExpand) {
          iconPath = "assets/icons/icon_down_arrow_selected.png";
        } else {
          iconPath = "assets/icons/icon_right_arrow_selected.png";
        }
      } else {
        if (node.isExpand) {
          iconPath = "assets/icons/icon_down_arrow_normal.png";
        } else {
          iconPath = "assets/icons/icon_right_arrow_normal.png";
        }
      }

      Image icon = Image.asset(iconPath, width: 20, height: 20);

      double indent = 0;

      if (null == currentDir || isRootDir) {
        indent = node.level * _INDENT_STEP;
      } else {
        indent = (node.level - currentDir.level - 1) * _INDENT_STEP;
      }

      return Visibility(
          child: GestureDetector(
              child:
              Container(child: icon, margin: EdgeInsets.only(left: indent)),
              onTap: () {
                debugPrint("Expand folder...");
                if (!node.isExpand) {
                  context.read<FileHomeBloc>().add(FileHomeExpandChildTree(node));
                } else {
                  context.read<FileHomeBloc>().add(FileHomeFoldUpChildTree(node));
                }
              }),
          maintainSize: true,
          maintainState: true,
          maintainAnimation: true,
          visible: node.data.isDir);
    }

    Image getFileTypeIcon(FileItem fileItem) {
      if (fileItem.isDir) {
        return Image.asset("assets/icons/icon_folder.png", width: 20, height: 20);
      }

      String name = fileItem.name.toLowerCase();

      if (name.endsWith(".jpg") ||
          name.endsWith(".jpeg") ||
          name.endsWith(".png")) {
        return Image.asset("assets/icons/icon_file_type_image.png",
            width: 20, height: 20);
      }

      if (name.endsWith(".mp3")) {
        return Image.asset("assets/icons/icon_file_type_audio.png",
            width: 20, height: 20);
      }

      if (name.endsWith(".txt")) {
        return Image.asset("assets/icons/icon_file_type_text.png",
            width: 20, height: 20);
      }

      return Image.asset("assets/icons/icon_file_type_doc.png", width: 20, height: 20);
    }

    List<DataRow> _generateRows() {
      return List<DataRow>.generate(files.length, (int index) {
        FileNode file = files[index];

        Color textColor = checkedFiles.contains(file)
            ? Colors.white
            : Color(0xff313237);
        TextStyle textStyle =
        TextStyle(fontSize: 14, color: textColor);

        final inputController = TextEditingController();

        inputController.text = file.data.name;

        final focusNode = FocusNode();

        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            inputController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: inputController.text.length);
          }
        });

        return DataRow2(
            cells: [
              DataCell(Listener(
                child: Container(
                  child: Row(children: [
                    getRightArrowIcon(0, file),
                    getFileTypeIcon(file.data),
                    SizedBox(width: 10.0),
                    Flexible(
                      child: Stack(
                        children: [
                          Visibility(
                            child: Text(file.data.name,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle),
                            visible: isRenamingMode ? currentRenamingFile != file : true,
                          ),
                          Visibility(
                            child: Container(
                              child: IntrinsicWidth(
                                child: TextField(
                                  controller: inputController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xffcccbcd),
                                              width: 3,
                                              style: BorderStyle.solid)),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xffcccbcd),
                                              width: 3,
                                              style: BorderStyle.solid),
                                          borderRadius: BorderRadius.circular(4)),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xffcccbcd),
                                              width: 4,
                                              style: BorderStyle.solid),
                                          borderRadius: BorderRadius.circular(4)),
                                      contentPadding:
                                      EdgeInsets.fromLTRB(8, 3, 8, 3)),
                                  cursorColor: Color(0xff333333),
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xff333333)),
                                  onChanged: (value) {
                                    context.read<FileHomeBloc>().add(FileHomeNewNameChanged(value));
                                  },
                                ),
                              ),
                              height: 30,
                              color: Colors.white,
                            ),
                            visible: isRenamingMode ? currentRenamingFile == file : false,
                            maintainState: false,
                            maintainSize: false,
                          )
                        ],
                      ),
                    )
                  ]),
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
                onPointerDown: (event) {
                  _tryToOpenMenu(context, event, file);
                },
              )),
              DataCell(Listener(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                  child: Text(
                      file.data.isDir
                          ? "--"
                          : CommonUtil.convertToReadableSize(file.data.size),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: textStyle),
                  color: Colors.transparent,
                ),
                onPointerDown: (event) {
                  _tryToOpenMenu(context, event, file);
                },
              )),
              DataCell(Listener(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                  child: Text(_convertToCategory(context, file.data),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: textStyle),
                  color: Colors.transparent,
                ),
                onPointerDown: (event) {
                  _tryToOpenMenu(context, event, file);
                },
              )),
              DataCell(Listener(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                  child: Text(CommonUtil.formatTime(file.data.changeDate, context.l10n.yMdHmPattern),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: textStyle),
                  color: Colors.transparent,
                ),
                onPointerDown: (event) {
                  _tryToOpenMenu(context, event, file);
                },
              )),
            ],
            selected: checkedFiles.contains(file),
            onSelectChanged: (isSelected) {
              debugPrint("onSelectChanged: $isSelected");
            },
            onTap: () {
              context.read<FileHomeBloc>().add(FileHomeCheckedChanged(file));

              FileNode? currentRenamingFile = context.read<FileHomeBloc>().state.currentRenamingFile;
              if (currentRenamingFile != file) {
                context.read<FileHomeBloc>().add(FileHomeRenameExit());
              }
            },
            onDoubleTap: () {
              if (file.data.isDir) {
                context.read<FileHomeBloc>().add(FileHomeOpenDir(file));
              } else {
                SystemAppLauncher.openFile(file.data);
              }
            },
            color: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.hovered)) {
                return Colors.red;
              }

              if (states.contains(MaterialState.pressed)) {
                return Colors.blue;
              }

              if (states.contains(MaterialState.selected)) {
                return Color(0xff5e86ec);
              }

              return Colors.white;
            }));
      });
    }

    return GestureDetector(
      child: Container(
        color: Colors.white,
        child: DataTable2(
          dividerThickness: 1,
          bottomMargin: 10,
          columnSpacing: 0,
          sortColumnIndex: sortColumn.index,
          sortAscending: sortDirection == FileHomeSortDirection.ascending,
          showCheckboxColumn: false,
          showBottomBorder: false,
          columns: [
            DataColumn2(
                label: Container(
                  child: Text(
                    context.l10n.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        inherit: true,
                        fontFamily: 'NotoSansSC'
                    ),
                  ),
                ),
                onSort: (sortColumnIndex, isSortAscending) {
                  FileHomeSortColumn sortColumn = FileHomeSortColumnX.convertToColumn(sortColumnIndex);
                  FileHomeSortDirection sortDirection = isSortAscending ?
                  FileHomeSortDirection.ascending : FileHomeSortDirection.descending;

                  context.read<FileHomeBloc>().add(FileHomeSortInfoChanged(sortColumn, sortDirection));
                },
                size: ColumnSize.L),
            DataColumn2(
                label: Container(
                    child: Text(
                      context.l10n.size,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          inherit: true,
                          fontFamily: 'NotoSansSC'
                      ),
                    ),
                    padding: EdgeInsets.only(left: 15)),
                onSort: (sortColumnIndex, isSortAscending) {
                  FileHomeSortColumn sortColumn = FileHomeSortColumnX.convertToColumn(sortColumnIndex);
                  FileHomeSortDirection sortDirection = isSortAscending ?
                  FileHomeSortDirection.ascending : FileHomeSortDirection.descending;

                  context.read<FileHomeBloc>().add(FileHomeSortInfoChanged(sortColumn, sortDirection));
                }),
            DataColumn2(
                label: Container(
                  child: Text(
                    context.l10n.type,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        inherit: true,
                        fontFamily: 'NotoSansSC'
                    ),
                  ),
                  padding: EdgeInsets.only(left: 15),
                )),
            DataColumn2(
                label: Container(
                  child: Text(
                    context.l10n.dateModified,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        inherit: true,
                        fontFamily: 'NotoSansSC'
                    ),
                  ),
                  padding: EdgeInsets.only(left: 15),
                ),
                onSort: (sortColumnIndex, isSortAscending) {
                  FileHomeSortColumn sortColumn = FileHomeSortColumnX.convertToColumn(sortColumnIndex);
                  FileHomeSortDirection sortDirection = isSortAscending ?
                  FileHomeSortDirection.ascending : FileHomeSortDirection.descending;

                  context.read<FileHomeBloc>().add(FileHomeSortInfoChanged(sortColumn, sortDirection));
                })
          ],
          rows: _generateRows(),
          headingRowHeight: 40,
          headingTextStyle: headerStyle,
          onSelectAll: (val) {},
          empty: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.green[200],
              child: Text("No download files"),
            ),
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
      onTap: () {
        context.read<FileHomeBloc>().add(FileHomeClearChecked());
        context.read<FileHomeBloc>().add(FileHomeRenameExit());
      },
    );
  }

  void _tryToOpenMenu(BuildContext context, PointerDownEvent event, FileNode file) {
    if (event.isRightMouseClick()) {
      List<FileNode> checkedFiles = context.read<FileHomeBloc>().state.checkedFiles;
      if (!checkedFiles.contains(file)) {
        context.read<FileHomeBloc>().add(
            FileHomeCheckedChanged(file));
      }

      context.read<FileHomeBloc>().add(FileHomeMenuStatusChanged(
          FileHomeMenuStatus(
              isOpened: true,
              position: event.position,
              current: file
          )
      ));
    }
  }

  String _convertToCategory(BuildContext context, FileItem item) {
    if (item.isDir) {
      return context.l10n.folder;
    } else {
      String name = item.name.toLowerCase();
      if (name.trim() == "") return "--";

      if (name.endsWith(".jpg") || name.endsWith(".jpeg")) {
        return context.l10n.jpegImage;
      }

      if (name.endsWith(".png")) {
        return context.l10n.pngImage;
      }

      if (name.endsWith(".raw")) {
        return context.l10n.rawImage;
      }

      if (name.endsWith(".mp3")) {
        return context.l10n.mp3Audio;
      }

      if (name.endsWith(".txt")) {
        return context.l10n.textFile;
      }

      return context.l10n.document;
    }
  }
}
