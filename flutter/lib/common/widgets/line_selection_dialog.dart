import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/hbbs/vip_api.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/vip_model.dart';

const List<String> _fallbackLineLabels = [
  '\u4e13\u4e1a\u7248-\u6807\u51c6\u7ebf\u8def',
  '\u666e\u901a\u7248-\u5317\u4eac1',
  '\u666e\u901a\u7248-\u4e0a\u6d771',
  '\u666e\u901a\u7248-\u5e7f\u5dde1',
  '\u666e\u901a\u7248-\u6210\u90fd1',
  '\u666e\u901a\u7248-\u4e1c\u4eac1',
];

const List<String> _lineDescriptionItems = [
  '\u5957\u9910\u53ea\u5206\u666e\u901a\u7248\u548c\u4e13\u4e1a\u7248\uff0c\u7ebf\u8def\u53ea\u662f\u8fde\u63a5\u65b9\u5f0f\u4e0d\u662f\u7b2c\u4e09\u79cd\u5957\u9910\u3002',
  '\u5bb6\u5ead\u5bbd\u5e26\u3001\u624b\u673a\u70ed\u70b9\u7b49\u666e\u901a\u7f51\u7edc\uff0c\u4f18\u5148\u7528\u6807\u51c6\u7ebf\u8def\u3002',
  '\u516c\u53f8\u6216\u6821\u56ed\u7f51\u7edc\u8fde\u63a5\u53d7\u9650\u65f6\uff0c\u518d\u5207\u6362\u5230\u516c\u53f8/\u6821\u56ed\u7f51\u7edc\u7ebf\u8def\u3002',
];

Future<void> showLineSelectionDialog(BuildContext context) async {
  final proceed = await _showDesktopLineDescriptionDialog();
  if (!proceed || !context.mounted) {
    return;
  }
  await _showDesktopLineChoiceDialog(context);
}

Future<void> showMobileLineSelectionSheet(BuildContext context) async {
  final proceed = await _showMobileLineDescriptionDialog(context);
  if (!proceed || !context.mounted) {
    return;
  }
  await _showMobileLineChoiceDialog(context);
}

Future<bool> _showDesktopLineDescriptionDialog() async {
  var proceed = false;
  await gFFI.dialogManager.show((setState, close, context) {
    return CustomAlertDialog(
      title: const Text('\u5982\u4f55\u9009\u62e9\u7ebf\u8def'),
      contentBoxConstraints: const BoxConstraints(maxWidth: 460),
      content: _buildDescriptionContent(),
      actions: [
        dialogButton(
          '\u7ee7\u7eed',
          onPressed: () {
            proceed = true;
            close();
          },
        ),
      ],
      onCancel: close,
    );
  });
  return proceed;
}

Future<bool> _showMobileLineDescriptionDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('\u5982\u4f55\u9009\u62e9\u7ebf\u8def'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _buildDescriptionContent(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('\u7ee7\u7eed'),
          ),
        ],
      );
    },
  );
  return result == true;
}

Widget _buildDescriptionContent() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < _lineDescriptionItems.length; i++) ...[
        Text(_lineDescriptionItems[i]),
        if (i != _lineDescriptionItems.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

Future<void> _showDesktopLineChoiceDialog(BuildContext context) async {
  final servers = await _loadServers();
  if (servers.isEmpty) {
    showToast('\u6682\u65e0\u53ef\u7528\u7ebf\u8def');
    return;
  }

  var selectedId = _initialSelectedId(servers);
  await gFFI.dialogManager.show((setState, close, dialogContext) {
    Future<void> submit(int serverId) async {
      final selected = servers.firstWhere(
        (server) => server.id == serverId,
        orElse: () => servers.first,
      );
      await _applyServerSelection(selected);
      close();
    }

    return CustomAlertDialog(
      title: const Text('\u9009\u62e9\u7ebf\u8def'),
      contentBoxConstraints:
          const BoxConstraints(maxWidth: 380, maxHeight: 440),
      content: StatefulBuilder(
        builder: (dialogContext, innerSetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < servers.length; i++)
                _LineOptionTile(
                  label: _serverLabel(i, servers[i]),
                  subtitle: _serverSubtitle(i, servers[i]),
                  selected: selectedId == servers[i].id,
                  highlight: i == 0,
                  onTap: () async {
                    innerSetState(() => selectedId = servers[i].id);
                    await submit(servers[i].id);
                  },
                ),
            ],
          );
        },
      ),
      actions: [
        dialogButton('\u53d6\u6d88', onPressed: close, isOutline: true),
      ],
      onCancel: close,
    );
  });
}

Future<void> _showMobileLineChoiceDialog(BuildContext context) async {
  final servers = await _loadServers();
  if (servers.isEmpty) {
    showToast('\u6682\u65e0\u53ef\u7528\u7ebf\u8def');
    return;
  }

  var selectedId = _initialSelectedId(servers);
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit(int serverId) async {
            final selected = servers.firstWhere(
              (server) => server.id == serverId,
              orElse: () => servers.first,
            );
            await _applyServerSelection(selected);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('\u9009\u62e9\u7ebf\u8def'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < servers.length; i++)
                    _LineOptionTile(
                      label: _serverLabel(i, servers[i]),
                      subtitle: _serverSubtitle(i, servers[i]),
                      selected: selectedId == servers[i].id,
                      highlight: i == 0,
                      onTap: () async {
                        setState(() => selectedId = servers[i].id);
                        await submit(servers[i].id);
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('\u53d6\u6d88'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<List<ServerNode>> _loadServers() async {
  final servers = await VipApi.getServers();
  servers.sort((a, b) {
    if (a.isDefault != b.isDefault) {
      return a.isDefault ? -1 : 1;
    }
    return b.priority.compareTo(a.priority);
  });
  return servers;
}

int _initialSelectedId(List<ServerNode> servers) {
  final savedNodeId = bind.mainGetLocalOption(key: 'selected_node_id');
  final parsedId = int.tryParse(savedNodeId);
  if (parsedId != null && servers.any((server) => server.id == parsedId)) {
    return parsedId;
  }
  final defaultServer = servers.firstWhere(
    (server) => server.isDefault,
    orElse: () => servers.first,
  );
  return defaultServer.id;
}

String _serverLabel(int index, ServerNode server) {
  final fallback = index < _fallbackLineLabels.length
      ? _fallbackLineLabels[index]
      : '\u666e\u901a\u7248-\u7ebf\u8def${index + 1}';
  final rawName = server.name.trim();
  String label;

  if (server.supportsWebSocket) {
    label = rawName.isEmpty
        ? '\u4e13\u4e1a\u7248-\u516c\u53f8/\u6821\u56ed\u7f51\u7edc\u7ebf\u8def'
        : rawName.replaceAll('\u4f01\u4e1a\u7248',
            '\u4e13\u4e1a\u7248-\u516c\u53f8/\u6821\u56ed\u7f51\u7edc\u7ebf\u8def');
    if (!label.contains('\u516c\u53f8/\u6821\u56ed\u7f51\u7edc')) {
      if (label.contains('\u4e13\u4e1a\u7248')) {
        label = label.replaceFirst(
          '\u4e13\u4e1a\u7248',
          '\u4e13\u4e1a\u7248-\u516c\u53f8/\u6821\u56ed\u7f51\u7edc\u7ebf\u8def',
        );
      } else {
        label =
            '\u4e13\u4e1a\u7248-\u516c\u53f8/\u6821\u56ed\u7f51\u7edc\u7ebf\u8def-$rawName';
      }
    }
  } else if (rawName.isEmpty) {
    label = fallback;
  } else if (rawName.contains('\u666e\u901a\u7248') ||
      rawName.contains('\u4e13\u4e1a\u7248')) {
    label = rawName;
  } else if (index == 0) {
    label = '\u4e13\u4e1a\u7248-$rawName';
  } else {
    label = '\u666e\u901a\u7248-$rawName';
  }

  if (label == '\u4e13\u4e1a\u7248') {
    return '\u4e13\u4e1a\u7248-\u6807\u51c6\u7ebf\u8def';
  }
  return label;
}

String? _serverSubtitle(int index, ServerNode server) {
  if (server.supportsWebSocket) {
    return '\u516c\u53f8\u3001\u6821\u56ed\u7b49\u53d7\u9650\u7f51\u7edc\u53ef\u7528';
  }
  if (_serverLabel(index, server).startsWith('\u4e13\u4e1a\u7248')) {
    return '\u9ed8\u8ba4\u63a8\u8350';
  }
  return null;
}

Future<void> _applyServerSelection(ServerNode selected) async {
  await bind.mainSetLocalOption(
    key: 'selected_node_id',
    value: selected.id.toString(),
  );
  await bind.mainSetLocalOption(
    key: kOptionSelectedNodeSupportsWebSocket,
    value: selected.supportsWebSocket ? 'Y' : 'N',
  );

  await setServerConfig(
    null,
    null,
    ServerConfig(
      idServer: selected.idServer,
      relayServer: selected.relayServer,
      apiServer: selected.apiServer,
      key: selected.key,
    ),
  );
  await mainSetBoolOption(kOptionAllowWebSocket, selected.supportsWebSocket);

  showToast(
      '\u7ebf\u8def\u5df2\u5207\u6362\uff0c\u6b63\u5728\u91cd\u65b0\u8fde\u63a5...');
  await bind.mainStopService();
  await bind.mainStartService();
}

class _LineOptionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final bool highlight;
  final VoidCallback onTap;

  const _LineOptionTile({
    required this.label,
    required this.selected,
    required this.highlight,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFF0F0F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (highlight) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: content,
    );
  }
}
