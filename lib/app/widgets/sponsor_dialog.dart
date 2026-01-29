import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class SponsorDialog extends StatelessWidget {
  const SponsorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('支持作者'),
      content: SizedBox(
        width: double.maxFinite, // 让对话框可以适应内容宽度
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '如果您喜欢我们的应用，请考虑赞助我们以支持后续开发。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '微信支付',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _openImageOrLink(context, 'assets/sponsor/wechat.png');
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildSponsorImage('assets/sponsor/wechat.png', '微信赞助码'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '支付宝支付',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                // 支付宝二维码图片
                GestureDetector(
                  onTap: () {
                    _openImageOrLink(context, 'assets/sponsor/alipay.jpg');
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildSponsorImage('assets/sponsor/alipay.jpg', '支付宝赞助码'),
                  ),
                ),
                const SizedBox(height: 16),
                // 支付宝跳转按钮
                ElevatedButton(
                  onPressed: () {
                    _launchAlipay(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('点击跳转到支付宝'),
                ),
              ],
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
            '关闭',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSponsorImage(String imagePath, String placeholderText) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Colors.grey,
              ),
            );
          },
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