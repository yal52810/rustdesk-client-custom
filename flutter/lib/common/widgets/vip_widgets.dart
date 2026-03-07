import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/hbbs/vip_api.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:get/get.dart';

const double _kDesktopCardWidth = 540;
const String _kRechargeEntryLabel = '\u8d26\u53f7\u5145\u503c';
const String _kRechargeDialogTitle = '\u8d26\u53f7\u5145\u503c';

Widget buildVipAccountPanel({
  required BuildContext context,
  required bool isDesktop,
}) {
  if (!isDesktop) {
    return const SizedBox.shrink();
  }
  return buildDesktopVipAccountCard(context);
}

Widget buildDesktopVipAccountCard(BuildContext context) {
  return Obx(() {
    final userName = gFFI.userModel.userName.value;
    final isLogin = userName.isNotEmpty;
    return Row(
      children: [
        Flexible(
          child: SizedBox(
            width: _kDesktopCardWidth,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\u8d26\u6237',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 18),
                    _DesktopActionButton(
                      label: isLogin ? '\u767b\u51fa' : '\u767b\u5f55',
                      onPressed: () {
                        if (isLogin) {
                          logOutConfirmDialog();
                        } else {
                          loginDialog();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _DesktopActionButton(
                      label: '\u6ce8\u518c',
                      onPressed: () => showVipRegisterDialog(
                        context,
                        desktop: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DesktopActionButton(
                      label: '\u67e5\u8be2\u5230\u671f\u65f6\u95f4',
                      onPressed: () => showVipExpireDialog(
                        context,
                        desktop: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DesktopActionButton(
                      label: _kRechargeEntryLabel,
                      onPressed: () => showVipRechargeDialog(
                        context,
                        desktop: true,
                      ),
                    ),
                    if (isLogin) ...[
                      const SizedBox(height: 16),
                      Text(
                        '\u5f53\u524d\u8d26\u53f7: $userName',
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ).marginOnly(left: 15, top: 15),
          ),
        ),
      ],
    );
  });
}

Widget buildFavoriteLoginEntry(BuildContext context) {
  return Obx(() {
    final isLogin = gFFI.userModel.userName.value.isNotEmpty;
    if (isLogin) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF7FAFF),
            Theme.of(context).cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MyTheme.accent.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: MyTheme.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: MyTheme.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u8d26\u53f7\u5165\u53e3',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\u767b\u5f55\u540e\u53ef\u5feb\u901f\u4f7f\u7528\u6536\u85cf\u5939\u3001\u5230\u671f\u67e5\u8be2\u548c\u8d26\u53f7\u5145\u503c\u3002',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: MyTheme.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '\u9996\u6b21\u4f7f\u7528\u53ef\u5148\u6ce8\u518c',
                        style: TextStyle(
                          fontSize: 12,
                          color: MyTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: loginDialog,
                    child: const Text(
                      '\u767b\u5f55',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MyTheme.accent,
                      side: const BorderSide(color: MyTheme.accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        showVipRegisterDialog(context, desktop: true),
                    child: const Text(
                      '\u6ce8\u518c',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

Future<void> showVipRegisterDialog(
  BuildContext context, {
  bool desktop = false,
}) async {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  if (desktop) {
    String? errorText;
    bool isLoading = false;
    await gFFI.dialogManager.show((setState, close, dialogContext) {
      Future<void> submit() async {
        final username = usernameController.text.trim();
        final email = emailController.text.trim();
        final password = passwordController.text.trim();
        final message = _validateRegisterInput(username, password, email);
        if (message != null) {
          setState(() => errorText = message);
          return;
        }

        setState(() {
          errorText = null;
          isLoading = true;
        });

        final success = await VipApi.register(
          username: username,
          password: password,
          email: email.isEmpty ? null : email,
        );

        if (success) {
          close();
          showToast('\u6ce8\u518c\u6210\u529f\uff0c\u8bf7\u767b\u5f55');
          await loginDialog();
          return;
        }

        setState(() {
          isLoading = false;
          errorText =
              '\u6ce8\u518c\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
        });
      }

      return CustomAlertDialog(
        title: const Text('\u7528\u6237\u6ce8\u518c'),
        contentBoxConstraints: const BoxConstraints(maxWidth: 320),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(
              controller: usernameController,
              hintText: '\u8bf7\u8f93\u5165\u8d26\u53f7\uff082-18\u4f4d\uff09',
            ),
            const SizedBox(height: 12),
            _dialogInput(
              controller: emailController,
              hintText:
                  '\u8bf7\u8f93\u5165\u90ae\u7bb1\uff08\u53ef\u9009\uff0c\u7528\u4e8e\u627e\u56de\u5bc6\u7801\uff09',
            ),
            const SizedBox(height: 12),
            _dialogInput(
              controller: passwordController,
              hintText: '\u8bf7\u8f93\u5165\u5bc6\u7801\uff086-18\u4f4d\uff09',
              obscureText: true,
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
        actions: [
          dialogButton('\u53d6\u6d88', onPressed: close, isOutline: true),
          dialogButton('\u63d0\u4ea4\u6ce8\u518c',
              onPressed: isLoading ? null : submit),
        ],
        onCancel: close,
        onSubmit: isLoading ? null : submit,
      );
    });
    return;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      String? errorText;
      bool isLoading = false;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            final username = usernameController.text.trim();
            final email = emailController.text.trim();
            final password = passwordController.text.trim();
            final message = _validateRegisterInput(username, password, email);
            if (message != null) {
              setState(() => errorText = message);
              return;
            }

            setState(() {
              errorText = null;
              isLoading = true;
            });

            final success = await VipApi.register(
              username: username,
              password: password,
              email: email.isEmpty ? null : email,
            );

            if (!dialogContext.mounted) {
              return;
            }

            if (success) {
              Navigator.of(dialogContext).pop();
              showToast('\u6ce8\u518c\u6210\u529f\uff0c\u8bf7\u767b\u5f55');
              await loginDialog();
              return;
            }

            setState(() {
              isLoading = false;
              errorText =
                  '\u6ce8\u518c\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('\u7528\u6237\u6ce8\u518c'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogInput(
                    controller: usernameController,
                    hintText:
                        '\u8bf7\u8f93\u5165\u8d26\u53f7\uff082-18\u4f4d\uff09',
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    controller: emailController,
                    hintText:
                        '\u8bf7\u8f93\u5165\u90ae\u7bb1\uff08\u53ef\u9009\uff0c\u7528\u4e8e\u627e\u56de\u5bc6\u7801\uff09',
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    controller: passwordController,
                    hintText:
                        '\u8bf7\u8f93\u5165\u5bc6\u7801\uff086-18\u4f4d\uff09',
                    obscureText: true,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              _mobileOutlineButton(
                label: '\u53d6\u6d88',
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              _mobileSolidButton(
                label: '\u63d0\u4ea4\u6ce8\u518c',
                onPressed: isLoading ? null : submit,
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.only(bottom: 18),
            contentPadding: const EdgeInsets.fromLTRB(28, 10, 28, 8),
            titlePadding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
          );
        },
      );
    },
  );
}

Future<void> showVipExpireDialog(
  BuildContext context, {
  bool desktop = false,
}) async {
  final canContinue = await _ensureVipLogin();
  if (!canContinue) {
    return;
  }

  final vipInfo = await VipApi.getVipInfo();
  final expireText = vipInfo?.expireDateStr ?? '\u672a\u77e5';

  if (desktop) {
    await gFFI.dialogManager.show((setState, close, dialogContext) {
      return CustomAlertDialog(
        title: const Text('\u8d26\u53f7\u6709\u6548\u671f'),
        contentBoxConstraints: const BoxConstraints(maxWidth: 360),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _expireRow(
              icon: Icons.star_border_rounded,
              title: '\u666e\u901a\u7248',
              value: expireText,
            ),
            const SizedBox(height: 24),
            _expireRow(
              icon: Icons.stars_rounded,
              title: '\u4e13\u4e1a\u7248',
              value: expireText,
            ),
          ],
        ),
        actions: [
          dialogButton('\u786e\u5b9a', onPressed: close),
        ],
        onCancel: close,
      );
    });
    return;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('\u8d26\u53f7\u6709\u6548\u671f'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _expireRow(
                icon: Icons.star_border_rounded,
                title: '\u666e\u901a\u7248',
                value: expireText,
              ),
              const SizedBox(height: 24),
              _expireRow(
                icon: Icons.stars_rounded,
                title: '\u4e13\u4e1a\u7248',
                value: expireText,
              ),
            ],
          ),
        ),
        actions: [
          _mobileSolidButton(
            label: '\u786e\u5b9a',
            minWidth: 92,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 18),
      );
    },
  );
}

Future<void> showVipRechargeDialog(
  BuildContext context, {
  bool desktop = false,
}) async {
  final canContinue = await _ensureVipLogin();
  if (!canContinue) {
    return;
  }

  final codeController = TextEditingController();
  final currentUser = gFFI.userModel.userName.value;

  if (desktop) {
    String? errorText;
    bool isLoading = false;
    await gFFI.dialogManager.show((setState, close, dialogContext) {
      Future<void> submit() async {
        final code = codeController.text.trim();
        if (code.isEmpty) {
          setState(() => errorText = '\u8bf7\u8f93\u5165\u5361\u5bc6');
          return;
        }

        setState(() {
          errorText = null;
          isLoading = true;
        });

        final result = await VipApi.redeem(code);
        if (result.success) {
          close();
          showToast(result.message.isEmpty
              ? '\u5145\u503c\u6210\u529f'
              : result.message);
          return;
        }

        setState(() {
          isLoading = false;
          errorText = result.message.isEmpty
              ? '\u5145\u503c\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5'
              : result.message;
        });
      }

      return CustomAlertDialog(
        title: const Text(_kRechargeDialogTitle),
        contentBoxConstraints: const BoxConstraints(maxWidth: 360),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u5f53\u524d\u8d26\u53f7: $currentUser',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 14),
            _dialogInput(
              controller: codeController,
              hintText: '\u8bf7\u8f93\u5165\u5361\u5bc6',
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
        actions: [
          dialogButton('\u53d6\u6d88', onPressed: close, isOutline: true),
          dialogButton('\u7acb\u5373\u5145\u503c',
              onPressed: isLoading ? null : submit),
        ],
        onCancel: close,
        onSubmit: isLoading ? null : submit,
      );
    });
    return;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      String? errorText;
      bool isLoading = false;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            final code = codeController.text.trim();
            if (code.isEmpty) {
              setState(() => errorText = '\u8bf7\u8f93\u5165\u5361\u5bc6');
              return;
            }

            setState(() {
              errorText = null;
              isLoading = true;
            });

            final result = await VipApi.redeem(code);
            if (!dialogContext.mounted) {
              return;
            }

            if (result.success) {
              Navigator.of(dialogContext).pop();
              showToast(result.message.isEmpty
                  ? '\u5145\u503c\u6210\u529f'
                  : result.message);
              return;
            }

            setState(() {
              isLoading = false;
              errorText = result.message.isEmpty
                  ? '\u5145\u503c\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5'
                  : result.message;
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(_kRechargeDialogTitle),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\u5f53\u524d\u8d26\u53f7: $currentUser',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  _dialogInput(
                    controller: codeController,
                    hintText: '\u8bf7\u8f93\u5165\u5361\u5bc6',
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              _mobileOutlineButton(
                label: '\u53d6\u6d88',
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              _mobileSolidButton(
                label: '\u7acb\u5373\u5145\u503c',
                onPressed: isLoading ? null : submit,
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.only(bottom: 18),
            contentPadding: const EdgeInsets.fromLTRB(26, 10, 26, 8),
            titlePadding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
          );
        },
      );
    },
  );
}

Future<bool> _ensureVipLogin() async {
  if (gFFI.userModel.userName.value.isNotEmpty) {
    return true;
  }
  final result = await loginDialog();
  return result == true && gFFI.userModel.userName.value.isNotEmpty;
}

String? _validateRegisterInput(String username, String password, String email) {
  if (username.length < 2 || username.length > 18) {
    return '\u8d26\u53f7\u957f\u5ea6\u9700\u4e3a 2-18 \u4f4d';
  }
  if (password.length < 6 || password.length > 18) {
    return '\u5bc6\u7801\u957f\u5ea6\u9700\u4e3a 6-18 \u4f4d';
  }
  if (email.isNotEmpty &&
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return '\u90ae\u7bb1\u683c\u5f0f\u4e0d\u6b63\u786e';
  }
  return null;
}

Widget _dialogInput({
  required TextEditingController controller,
  required String hintText,
  bool obscureText = false,
}) {
  return TextField(
    controller: controller,
    obscureText: obscureText,
    decoration: InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD8DCE6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD8DCE6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MyTheme.accent, width: 1.4),
      ),
    ),
  );
}

Widget _expireRow({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 30, color: Colors.grey.shade600).marginOnly(top: 2),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    ],
  );
}

class _DesktopActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DesktopActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyTheme.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

Widget _mobileOutlineButton({
  required String label,
  required VoidCallback? onPressed,
  double minWidth = 92,
}) {
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: Size(minWidth, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      side: const BorderSide(color: MyTheme.accent, width: 1.6),
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontSize: 15)),
  );
}

Widget _mobileSolidButton({
  required String label,
  required VoidCallback? onPressed,
  double minWidth = 110,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(minWidth, 42),
      backgroundColor: MyTheme.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontSize: 15)),
  );
}
