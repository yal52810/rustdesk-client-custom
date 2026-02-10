import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/models/vip_model.dart';
import 'package:flutter_hbb/common/hbbs/vip_api.dart';
import 'package:get/get.dart';

Widget buildVipAccountPanel({
  required BuildContext context,
  required bool isDesktop,
}) {
  return Obx(() {
    final isLogin = gFFI.userModel.isLogin;
    final userName = gFFI.userModel.userName.value;

    if (isDesktop) {
      return _DesktopVipPanel(
        isLogin: isLogin,
        userName: userName,
      );
    } else {
      return _MobileVipPanel(
        isLogin: isLogin,
        userName: userName,
      );
    }
  });
}

class _DesktopVipPanel extends StatefulWidget {
  final bool isLogin;
  final String userName;

  const _DesktopVipPanel({
    required this.isLogin,
    required this.userName,
  });

  @override
  State<_DesktopVipPanel> createState() => _DesktopVipPanelState();
}

class _DesktopVipPanelState extends State<_DesktopVipPanel> {
  VipInfo? _vipInfo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLogin) {
      _loadVipInfo();
    }
  }

  Future<void> _loadVipInfo() async {
    if (_loading) return;
    setState(() => _loading = true);
    _vipInfo = await VipApi.getVipInfo();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;

    return Container(
      margin: EdgeInsets.only(left: 20, right: 16, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 2,
                height: 20,
                decoration: BoxDecoration(color: MyTheme.accent),
              ),
              SizedBox(width: 7),
              Text(
                '账户',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (widget.isLogin) ...[
            Padding(
              padding: EdgeInsets.only(left: 9),
              child: Text(
                '用户: ${widget.userName}',
                style: TextStyle(fontSize: 13, color: textColor),
              ),
            ),
            if (_vipInfo != null) ...[
              SizedBox(height: 5),
              Padding(
                padding: EdgeInsets.only(left: 9),
                child: Text(
                  '到期: ${_vipInfo!.expireDateStr}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _vipInfo!.isExpired 
                      ? Colors.red 
                      : textColor?.withOpacity(0.7),
                  ),
                ),
              ),
            ],
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 9),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallButton(
                    text: '登出',
                    onTap: () => logOutConfirmDialog(),
                  ),
                  _SmallButton(
                    text: '查到期',
                    onTap: () => _showExpireDialog(),
                  ),
                  _SmallButton(
                    text: '充值',
                    onTap: () => _showRechargeDialog(),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: EdgeInsets.only(left: 9),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallButton(
                    text: '登录',
                    onTap: () => loginDialog(),
                  ),
                  _SmallButton(
                    text: '注册',
                    onTap: () => _showRegisterDialog(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExpireDialog() async {
    await _loadVipInfo();
    if (!mounted) return;
    
    gFFI.dialogManager.show((setState, close, context) {
      return CustomAlertDialog(
        title: Text('服务到期时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_vipInfo != null) ...[
              Text('用户名: ${_vipInfo!.username}'),
              SizedBox(height: 10),
              Text('到期时间: ${_vipInfo!.expireDateStr}'),
              SizedBox(height: 10),
              if (_vipInfo!.isLifetime)
                Text('账户类型: 永久会员', style: TextStyle(color: Colors.orange))
              else if (_vipInfo!.isExpired)
                Text('状态: 已过期', style: TextStyle(color: Colors.red))
              else
                Text('剩余天数: ${_vipInfo!.remainingDays} 天', 
                  style: TextStyle(color: Colors.green)),
            ] else ...[
              Text('获取信息失败，请重试'),
            ],
          ],
        ),
        actions: [
          dialogButton('OK', onPressed: close),
        ],
        onCancel: close,
      );
    });
  }

  void _showRechargeDialog() {
    final codeController = TextEditingController();
    final RxBool isLoading = false.obs;

    gFFI.dialogManager.show((setState, close, context) {
      Future<void> onConfirm() async {
        final code = codeController.text.trim();
        if (code.isEmpty) {
          showToast('请输入激活码');
          return;
        }

        isLoading.value = true;
        final result = await VipApi.redeem(code);
        isLoading.value = false;

        if (result.success) {
          close();
          showToast(result.addedDays != null 
            ? '激活成功，增加 ${result.addedDays} 天' 
            : '激活成功');
          _loadVipInfo();
        } else {
          showToast(result.message);
        }
      }

      return CustomAlertDialog(
        title: Text('激活码充值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: '激活码',
                hintText: '请输入激活码',
              ),
            ),
            SizedBox(height: 10),
            Obx(() => isLoading.value 
              ? LinearProgressIndicator() 
              : SizedBox()),
          ],
        ),
        actions: [
          dialogButton('Cancel', onPressed: close, isOutline: true),
          dialogButton('激活', onPressed: onConfirm),
        ],
        onCancel: close,
        onSubmit: onConfirm,
      );
    });
  }

  void _showRegisterDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    final RxBool isLoading = false.obs;
    String? errorMsg;

    gFFI.dialogManager.show((setState, close, context) {
      Future<void> onRegister() async {
        final username = usernameController.text.trim();
        final password = passwordController.text.trim();

        if (username.isEmpty) {
          setState(() => errorMsg = '请输入用户名');
          return;
        }
        if (password.isEmpty) {
          setState(() => errorMsg = '请输入密码');
          return;
        }

        isLoading.value = true;
        final success = await VipApi.register(
          username: username,
          password: password,
          email: emailController.text.trim(),
          activationCode: codeController.text.trim(),
        );
        isLoading.value = false;

        if (success) {
          close();
          showToast('注册成功，请登录');
          loginDialog();
        } else {
          setState(() => errorMsg = '注册失败，请重试');
        }
      }

      return CustomAlertDialog(
        title: Text('注册'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogTextField(
              title: '用户名',
              controller: usernameController,
              prefixIcon: DialogTextField.kUsernameIcon,
              errorText: errorMsg != null && usernameController.text.isEmpty 
                ? errorMsg : null,
            ),
            PasswordWidget(
              controller: passwordController,
              autoFocus: false,
              reRequestFocus: false,
            ),
            DialogTextField(
              title: '邮箱 (可选)',
              controller: emailController,
              prefixIcon: Icons.email,
            ),
            DialogTextField(
              title: '激活码 (可选)',
              controller: codeController,
              prefixIcon: Icons.vpn_key,
            ),
            if (errorMsg != null && usernameController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
              ),
            Obx(() => isLoading.value 
              ? Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ) 
              : SizedBox()),
          ],
        ),
        actions: [
          dialogButton('Cancel', onPressed: close, isOutline: true),
          dialogButton('注册', onPressed: onRegister),
        ],
        onCancel: close,
        onSubmit: onRegister,
      );
    });
  }
}

class _MobileVipPanel extends StatelessWidget {
  final bool isLogin;
  final String userName;

  const _MobileVipPanel({
    required this.isLogin,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLogin) ...[
          ListTile(
            leading: Icon(Icons.person),
            title: Text('登出 ($userName)'),
            onTap: () => logOutConfirmDialog(),
          ),
          ListTile(
            leading: Icon(Icons.timer),
            title: Text('查询到期时间'),
            onTap: () => _showExpireDialogMobile(context),
          ),
          ListTile(
            leading: Icon(Icons.card_giftcard),
            title: Text('充值'),
            onTap: () => _showRechargeDialogMobile(context),
          ),
        ] else ...[
          ListTile(
            leading: Icon(Icons.login),
            title: Text('登录'),
            onTap: () => loginDialog(),
          ),
          ListTile(
            leading: Icon(Icons.app_registration),
            title: Text('注册'),
            onTap: () => _showRegisterDialogMobile(context),
          ),
        ],
      ],
    );
  }

  void _showExpireDialogMobile(BuildContext context) async {
    final vipInfo = await VipApi.getVipInfo();
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('服务到期时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vipInfo != null) ...[
              Text('用户名: ${vipInfo.username}'),
              SizedBox(height: 10),
              Text('到期时间: ${vipInfo.expireDateStr}'),
              SizedBox(height: 10),
              if (vipInfo.isLifetime)
                Text('账户类型: 永久会员', style: TextStyle(color: Colors.orange))
              else if (vipInfo.isExpired)
                Text('状态: 已过期', style: TextStyle(color: Colors.red))
              else
                Text('剩余天数: ${vipInfo.remainingDays} 天', 
                  style: TextStyle(color: Colors.green)),
            ] else ...[
              Text('获取信息失败，请重试'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showRechargeDialogMobile(BuildContext context) {
    final codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('激活码充值'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: '激活码',
                  hintText: '请输入激活码',
                ),
              ),
              if (isLoading) 
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isEmpty) {
                  showToast('请输入激活码');
                  return;
                }

                setState(() => isLoading = true);
                final result = await VipApi.redeem(code);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  showToast(result.success 
                    ? '激活成功' 
                    : result.message);
                }
              },
              child: Text('激活'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterDialogMobile(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('注册'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: '邮箱 (可选)',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: '激活码 (可选)',
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                ),
                if (isLoading) 
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                if (username.isEmpty || password.isEmpty) {
                  showToast('请填写用户名和密码');
                  return;
                }

                setState(() => isLoading = true);
                final success = await VipApi.register(
                  username: username,
                  password: password,
                  email: emailController.text.trim(),
                  activationCode: codeController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    showToast('注册成功，请登录');
                    loginDialog();
                  } else {
                    showToast('注册失败，请重试');
                  }
                }
              },
              child: Text('注册'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SmallButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: MyTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: MyTheme.accent.withOpacity(0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: MyTheme.accent,
          ),
        ),
      ),
    );
  }
}

Future<void> showMobileLineSelectionSheet(BuildContext context) async {
  final servers = await VipApi.getServers();
  if (!context.mounted) return;

  final savedNodeId = bind.mainGetLocalOption(key: 'selected_node_id');
  int selectedId = int.tryParse(savedNodeId) ?? -1;

  if (servers.isEmpty) {
    showToast('暂无可用线路');
    return;
  }

  if (selectedId == -1) {
    final defaultServer = servers.firstWhere(
      (s) => s.isDefault,
      orElse: () => servers.first,
    );
    selectedId = defaultServer.id;
  }

  showModalBottomSheet(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择离您最近的地域降低延迟',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...servers.map((server) => RadioListTile<int>(
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
                ],
              ),
              value: server.id,
              groupValue: selectedId,
              onChanged: server.isOnline 
                ? (value) => setState(() => selectedId = value!)
                : null,
            )),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final selected = servers.firstWhere(
                      (s) => s.id == selectedId,
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

                    Navigator.pop(context);
                    showToast('线路已切换，正在重新连接...');
                    await bind.mainRestartService();
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
