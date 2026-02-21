import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../widgets/conditional_glass_effect.dart';

class SponsorDialog extends StatelessWidget {
  const SponsorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ConditionalGlassDialog(
      title: Row(
        children: [
          Icon(
            Icons.favorite,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('支持开发者'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 感谢文案
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.volunteer_activism,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '感谢您的支持！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '您的每一份支持都是对我们持续开发和维护的最大鼓励。我们将继续努力为您提供更好的体验！',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 支付方式标题
            Text(
              '选择支付方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // 微信支付卡片
            _buildPaymentCard(
              context: context,
              title: '微信支付',
              subtitle: '长按识别二维码',
              icon: Icons.wechat,
              iconColor: const Color(0xFF07C160),
              imagePath: 'assets/sponsor/wechat.png',
              onTap: () => _openImageOrLink(context, 'assets/sponsor/wechat.png'),
            ),
            
            const SizedBox(height: 16),
            
            // 支付宝支付卡片
            _buildPaymentCard(
              context: context,
              title: '支付宝',
              subtitle: '扫码或点击跳转',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue,
              imagePath: 'assets/sponsor/alipay.jpg',
              onTap: () => _openImageOrLink(context, 'assets/sponsor/alipay.jpg'),
              trailingWidget: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  onPressed: () => _launchAlipay(context),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('立即支付'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 温馨提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '支付完成后，您可以在应用内留言告知，我们会及时回复感谢！',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '稍后再看',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('好的，谢谢'),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String imagePath,
    required VoidCallback onTap,
    Widget? trailingWidget,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else
              Icon(
                Icons.qr_code_scanner,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  void _openImageOrLink(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: InteractiveViewer(
                    child: Image.asset(
                      imagePath,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('图片加载失败'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 支付宝跳转功能
  void _launchAlipay(BuildContext context) async {
    const alipayUrl = 'https://qr.alipay.com/fkx11218u46tujtugsjj3a8';
    
    if (await canLaunchUrl(Uri.parse(alipayUrl))) {
      await launchUrl(
        Uri.parse(alipayUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      // 如果无法直接打开支付宝，复制链接到剪贴板
      await Clipboard.setData(const ClipboardData(text: alipayUrl));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('支付宝链接已复制到剪贴板，请在支付宝中粘贴打开'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}