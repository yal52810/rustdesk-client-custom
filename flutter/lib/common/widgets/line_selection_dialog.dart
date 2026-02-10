import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/vip_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/common/hbbs/vip_api.dart';
import 'package:get/get.dart';

Future<void> showLineSelectionDialog(BuildContext context) async {
  final RxBool isLoading = true.obs;
  final RxList<ServerNode> servers = <ServerNode>[].obs;
  final RxInt selectedId = (-1).obs;

  final savedNodeId = bind.mainGetLocalOption(key: 'selected_node_id');
  if (savedNodeId.isNotEmpty) {
    selectedId.value = int.tryParse(savedNodeId) ?? -1;
  }

  Future<void> loadServers() async {
    isLoading.value = true;
    final list = await VipApi.getServers();
    servers.value = list;
    if (list.isNotEmpty && selectedId.value == -1) {
      final defaultServer = list.firstWhere(
        (s) => s.isDefault,
        orElse: () => list.first,
      );
      selectedId.value = defaultServer.id;
    }
    isLoading.value = false;
  }

  await loadServers();

  if (!context.mounted) return;

  await gFFI.dialogManager.show((setState, close, context) {
    Future<void> onConfirm() async {
      final selected = servers.firstWhere(
        (s) => s.id == selectedId.value,
        orElse: () => servers.first,
      );

      await bind.mainSetLocalOption(
        key: 'selected_node_id',
        value: selected.id.toString(),
      );

      await setServerConfig(null, null, ServerConfig(
        idServer: selected.idServer,
        relayServer: selected.relayServer,
        apiServer: selected.apiServer,
        key: selected.key,
      ));

      close();

      showToast('线路已切换，正在重新连接...');

      await bind.mainRestartService();
    }

    return CustomAlertDialog(
      title: Text('选择离您最近的地域降低延迟'),
      contentBoxConstraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
      content: Obx(() {
        if (isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (servers.isEmpty) {
          return Center(child: Text('暂无可用线路'));
        }

        final sortedServers = List<ServerNode>.from(servers)
          ..sort((a, b) => b.priority.compareTo(a.priority));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: sortedServers.map((server) {
            return RadioListTile<int>(
              title: Row(
                children: [
                  Text(server.name),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: server.isOnline 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '(${server.statusText})',
                      style: TextStyle(
                        fontSize: 12,
                        color: server.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                  if (server.isDefault) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '默认',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: server.description.isNotEmpty 
                ? Text(server.description, style: TextStyle(fontSize: 12))
                : null,
              value: server.id,
              groupValue: selectedId.value,
              onChanged: server.isOnline 
                ? (value) => selectedId.value = value!
                : null,
            );
          }).toList(),
        );
      }),
      actions: [
        dialogButton('Cancel', onPressed: close, isOutline: true),
        dialogButton('Confirm', onPressed: onConfirm),
      ],
      onCancel: close,
    );
  });
}
