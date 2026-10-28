import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/food_item.dart';

/// วิดเจ็ตแสดงผลรูปภาพอาหารอัจฉริยะ รองรับทั้ง:
/// 1. รูปภาพจริงจากกล้อง/คลังภาพในอุปกรณ์ (Local File / file://)
/// 2. รูปภาพ Base64 Data URI (data:image/...)
/// 3. รูปภาพจากอินเทอร์เน็ต (http://, https://) เช่น Open Food Facts
/// 4. รูปภาพจาก Assets (assets/...)
/// 5. Fallback อัตโนมัติไปยังรูปจำลองที่ตรงหมวดหมู่ หรือ Placeholder Icon
class FoodImageView extends StatelessWidget {
  final FoodItem item;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const FoodImageView({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildRawImage(context);

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }

  Widget _buildRawImage(BuildContext context) {
    final rawUrl = item.imageUrl?.trim() ?? '';

    // 1. ตรวจสอบว่าเป็นรูปภาพจริงในอุปกรณ์ (Local file) หรือ Base64 หรือ Network URL
    if (rawUrl.isNotEmpty) {
      // 1.1 Base64 Data URI
      if (rawUrl.startsWith('data:image')) {
        try {
          final commaIndex = rawUrl.indexOf(',');
          final base64Str =
              commaIndex != -1 ? rawUrl.substring(commaIndex + 1) : rawUrl;
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => _buildFallback(context),
          );
        } catch (_) {}
      }

      // 1.2 Local File Path จากกล้องถ่ายรูปจริง (เช่น /data/user/0/.../cache/CAP_xxx.jpg หรือ file://)
      try {
        String path = rawUrl;
        if (path.startsWith('file://')) {
          path = path.substring(7);
        }
        if (!path.startsWith('http://') &&
            !path.startsWith('https://') &&
            !path.startsWith('assets/')) {
          final file = File(path);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, _, _) => _buildFallback(context),
            );
          }
        }
      } catch (_) {}

      // 1.3 Network URL (Open Food Facts หรือ URL ภายนอก)
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        return Image.network(
          rawUrl,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildFallback(context),
        );
      }

      // 1.4 Asset Image
      if (rawUrl.startsWith('assets/')) {
        return Image.asset(
          rawUrl,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildFallback(context),
        );
      }
    }

    // 2. หากไม่มี imageUrl ให้ใช้ effectiveImageUrl (ภาพตามหมวดหมู่จริง)
    final effectiveUrl = item.effectiveImageUrl;
    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      return Image.network(
        effectiveUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildFallback(context),
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          item.isAi ? Icons.auto_awesome : Icons.qr_code_scanner_rounded,
          color: const Color(0xFF8B5CF6),
          size: (width != null && height != null)
              ? (width! * 0.45).clamp(16.0, 48.0)
              : 24,
        ),
      ),
    );
  }
}
