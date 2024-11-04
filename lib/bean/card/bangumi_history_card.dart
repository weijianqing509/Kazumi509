import 'package:flutter/material.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/utils/constans.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/favorite/favorite_controller.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:logger/logger.dart';
import 'package:kazumi/utils/logger.dart';

// 视频历史记录卡片 - 水平布局
class BangumiHistoryCardV extends StatefulWidget {
  const BangumiHistoryCardV(
      {super.key, required this.historyItem, this.showDelete = true});

  final History historyItem;
  final bool showDelete;

  @override
  State<BangumiHistoryCardV> createState() => _BangumiHistoryCardVState();
}

class _BangumiHistoryCardVState extends State<BangumiHistoryCardV> {
  late bool isFavorite;
  final VideoPageController videoPageController =
      Modular.get<VideoPageController>();
  final PluginsController pluginsController = Modular.get<PluginsController>();
  final HistoryController historyController = Modular.get<HistoryController>();

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(
        fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
        overflow: TextOverflow.ellipsis);
    final InfoController infoController = Modular.get<InfoController>();
    final FavoriteController favoriteController =
        Modular.get<FavoriteController>();
    isFavorite = favoriteController.isFavorite(widget.historyItem.bangumiItem);
    return SizedBox(
      height: 150,
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: InkWell(
          onTap: () async {
            if (widget.showDelete) {
              SmartDialog.showToast('编辑模式',
                  displayType: SmartToastType.onlyRefresh);
              return;
            }
            SmartDialog.showLoading(msg: '获取中');
            bool flag = false;
            for (Plugin plugin in pluginsController.pluginList) {
              if (plugin.name == widget.historyItem.adapterName) {
                videoPageController.currentPlugin = plugin;
                flag = true;
              }
            }
            if (!flag) {
              SmartDialog.dismiss();
              SmartDialog.showToast('未找到关联番剧源');
              return;
            }
            infoController.bangumiItem = widget.historyItem.bangumiItem;
            videoPageController.title =
                widget.historyItem.bangumiItem.nameCn == ''
                    ? widget.historyItem.bangumiItem.name
                    : widget.historyItem.bangumiItem.nameCn;
            videoPageController.src = widget.historyItem.lastSrc;
            try {
              await infoController.queryRoads(widget.historyItem.lastSrc,
                  videoPageController.currentPlugin.name);
              SmartDialog.dismiss();
              Modular.to.pushNamed('/video/');
            } catch (e) {
              KazumiLogger().log(Level.warning, e.toString());
              SmartDialog.dismiss();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: StyleString.imgRadius,
                    topRight: StyleString.imgRadius,
                    bottomLeft: StyleString.imgRadius,
                    bottomRight: StyleString.imgRadius,
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.65,
                    child: LayoutBuilder(builder: (context, boxConstraints) {
                      final double maxWidth = boxConstraints.maxWidth;
                      final double maxHeight = boxConstraints.maxHeight;
                      return NetworkImgLayer(
                        src: widget.historyItem.bangumiItem.images['large'] ??
                            '',
                        width: maxWidth,
                        height: maxHeight,
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: widget.historyItem.bangumiItem.nameCn == ''
                                  ? widget.historyItem.bangumiItem.name
                                  : (widget.historyItem.bangumiItem.nameCn),
                              style: TextStyle(
                                fontSize: MediaQuery.textScalerOf(context)
                                    .scale(Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .fontSize!),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 测试 因为API问题评分功能搁置
                      Text('番剧源: ${widget.historyItem.adapterName}',
                          style: style),
                      Text(
                          widget.historyItem.lastWatchEpisodeName == ''
                              ? '上次看到: 第${widget.historyItem.lastWatchEpisode}话'
                              : '上次看到: ${widget.historyItem.lastWatchEpisodeName}',
                          style: style),
                      Text('排名: ${widget.historyItem.bangumiItem.rank}',
                          style: style),
                      Text(
                          widget.historyItem.bangumiItem.type == 2
                              ? '番剧'
                              : '其他',
                          style: style),
                      Text(widget.historyItem.bangumiItem.airDate,
                          style: style),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_outline),
                      onPressed: () async {
                        if (isFavorite) {
                          favoriteController
                              .deleteFavorite(widget.historyItem.bangumiItem);
                        } else {
                          favoriteController
                              .addFavorite(widget.historyItem.bangumiItem);
                        }
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      },
                    ),
                    widget.showDelete
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              historyController
                                  .deleteHistory(widget.historyItem);
                            },
                          )
                        : Container(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
