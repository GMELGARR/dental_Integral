import 'package:flutter/material.dart';

import '../../domain/entities/odontogram.dart';

/// Color mapping for each tooth condition.
Color conditionColor(ToothCondition condition) {
  switch (condition) {
    case ToothCondition.sano:
      return Colors.white;
    case ToothCondition.caries:
      return const Color(0xFFE53935);
    case ToothCondition.obturacion:
      return const Color(0xFF1E88E5);
    case ToothCondition.corona:
      return const Color(0xFFFDD835);
    case ToothCondition.extraccion:
      return const Color(0xFF546E7A);
    case ToothCondition.ausente:
      return const Color(0xFFBDBDBD);
    case ToothCondition.endodoncia:
      return const Color(0xFF43A047);
    case ToothCondition.protesisFija:
      return const Color(0xFF8E24AA);
    case ToothCondition.sellante:
      return const Color(0xFF29B6F6);
  }
}

// ───────────── Tooth type helpers ─────────────

enum _ToothType { incisor, canine, premolar, molar }

_ToothType _toothType(String number) {
  final d = int.parse(number.substring(1));
  if (d <= 2) return _ToothType.incisor;
  if (d == 3) return _ToothType.canine;
  if (d <= 5) return _ToothType.premolar;
  return _ToothType.molar;
}

bool _isUpper(String number) => int.parse(number[0]) <= 2;

// ───────────── Widget ─────────────

/// A single tooth rendered with 5 faces, anatomically shaped per tooth type
/// (molar / premolar / canine / incisor) with curved root indicators.
class ToothWidget extends StatelessWidget {
  const ToothWidget({
    super.key,
    required this.toothNumber,
    required this.state,
    required this.onFaceTap,
    required this.onLongPress,
    this.size = 44,
    this.isSelected = false,
  });

  final String toothNumber;
  final ToothState state;
  final void Function(ToothFace face) onFaceTap;
  final VoidCallback onLongPress;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isSelected
        ? const Color(0xFF0D7377)
        : (isDark ? Colors.white24 : Colors.black26);

    final type = _toothType(toothNumber);
    final upper = _isUpper(toothNumber);
    final crownW = _crownWidth(type);
    final crownH = size * 0.85;
    final rootH = size * 0.38;
    final totalH = crownH + rootH;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          toothNumber,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onLongPress: onLongPress,
          child: SizedBox(
            width: size,
            height: totalH,
            child: CustomPaint(
              painter: _ToothPainter(
                state: state,
                borderColor: borderColor,
                isDark: isDark,
                type: type,
                isUpper: upper,
                crownWidth: crownW,
                crownHeight: crownH,
                rootHeight: rootH,
                totalWidth: size,
              ),
              child: _buildTouchAreas(crownW, crownH, upper, rootH),
            ),
          ),
        ),
      ],
    );
  }

  double _crownWidth(_ToothType type) {
    switch (type) {
      case _ToothType.molar:
        return size;
      case _ToothType.premolar:
        return size * 0.82;
      case _ToothType.canine:
        return size * 0.66;
      case _ToothType.incisor:
        return size * 0.60;
    }
  }

  Widget _buildTouchAreas(
      double crownW, double crownH, bool upper, double rootH) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final offsetX = (size - crownW) / 2;
        final offsetY = upper ? rootH : 0.0;
        final thirdW = crownW / 3;
        final thirdH = crownH / 3;

        return Stack(
          children: [
            // Vestibular (top band – full width)
            Positioned(
              left: offsetX,
              top: offsetY,
              width: crownW,
              height: thirdH,
              child: GestureDetector(
                onTap: () => onFaceTap(ToothFace.vestibular),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Mesial (left)
            Positioned(
              left: offsetX,
              top: offsetY + thirdH,
              width: thirdW,
              height: thirdH,
              child: GestureDetector(
                onTap: () => onFaceTap(ToothFace.mesial),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Oclusal (center)
            Positioned(
              left: offsetX + thirdW,
              top: offsetY + thirdH,
              width: thirdW,
              height: thirdH,
              child: GestureDetector(
                onTap: () => onFaceTap(ToothFace.oclusal),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Distal (right)
            Positioned(
              left: offsetX + thirdW * 2,
              top: offsetY + thirdH,
              width: thirdW,
              height: thirdH,
              child: GestureDetector(
                onTap: () => onFaceTap(ToothFace.distal),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Lingual (bottom band – full width)
            Positioned(
              left: offsetX,
              top: offsetY + thirdH * 2,
              width: crownW,
              height: thirdH,
              child: GestureDetector(
                onTap: () => onFaceTap(ToothFace.lingual),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────── Painter ─────────────

class _ToothPainter extends CustomPainter {
  _ToothPainter({
    required this.state,
    required this.borderColor,
    required this.isDark,
    required this.type,
    required this.isUpper,
    required this.crownWidth,
    required this.crownHeight,
    required this.rootHeight,
    required this.totalWidth,
  });

  final ToothState state;
  final Color borderColor;
  final bool isDark;
  final _ToothType type;
  final bool isUpper;
  final double crownWidth;
  final double crownHeight;
  final double rootHeight;
  final double totalWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final offsetX = (totalWidth - crownWidth) / 2;
    final crownTop = isUpper ? rootHeight : 0.0;
    final crownRect =
        Rect.fromLTWH(offsetX, crownTop, crownWidth, crownHeight);
    final crownPath = _crownOutline(crownRect);
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1 ── roots (behind crown)
    _drawRoots(canvas, crownRect);

    // 2 ── face fills
    if (state.wholeTooth != null) {
      final fill = Paint()
        ..color = conditionColor(state.wholeTooth!)
        ..style = PaintingStyle.fill;
      canvas.drawPath(crownPath, fill);
      canvas.drawPath(crownPath, strokePaint);

      canvas.save();
      canvas.clipPath(crownPath);
      _drawInternalLines(canvas, crownRect, strokePaint);
      canvas.restore();

      if (state.wholeTooth == ToothCondition.extraccion) {
        _drawExtraction(canvas, crownRect);
      }
      return;
    }

    // Individual faces clipped to crown silhouette
    canvas.save();
    canvas.clipPath(crownPath);
    _drawFace(canvas, _vestibularPath(crownRect),
        state.faces[ToothFace.vestibular], bgColor);
    _drawFace(canvas, _mesialPath(crownRect),
        state.faces[ToothFace.mesial], bgColor);
    _drawFace(canvas, _oclusalPath(crownRect),
        state.faces[ToothFace.oclusal], bgColor);
    _drawFace(canvas, _distalPath(crownRect),
        state.faces[ToothFace.distal], bgColor);
    _drawFace(canvas, _lingualPath(crownRect),
        state.faces[ToothFace.lingual], bgColor);
    canvas.restore();

    // 3 ── crown border
    canvas.drawPath(crownPath, strokePaint);

    // 4 ── internal curved lines (clipped)
    canvas.save();
    canvas.clipPath(crownPath);
    _drawInternalLines(canvas, crownRect, strokePaint);
    canvas.restore();
  }

  // ── Crown outlines per tooth type ──────────────────────────

  Path _crownOutline(Rect cr) {
    switch (type) {
      case _ToothType.molar:
        return _molarCrown(cr);
      case _ToothType.premolar:
        return _premolarCrown(cr);
      case _ToothType.canine:
        return _canineCrown(cr);
      case _ToothType.incisor:
        return _incisorCrown(cr);
    }
  }

  /// Wide, slightly rounded rectangle.
  Path _molarCrown(Rect cr) {
    final r = cr.width * 0.14;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(cr, Radius.circular(r)));
  }

  /// Medium rounded rectangle.
  Path _premolarCrown(Rect cr) {
    final r = cr.width * 0.20;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(cr, Radius.circular(r)));
  }

  /// Oval / shield shape – distinctive canine silhouette.
  Path _canineCrown(Rect cr) {
    return Path()..addOval(cr);
  }

  /// Tall capsule (very rounded corners).
  Path _incisorCrown(Rect cr) {
    final r = cr.width * 0.34;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(cr, Radius.circular(r)));
  }

  // ── Roots ─────────────────────────────────────────────────

  void _drawRoots(Canvas canvas, Rect cr) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final cx = cr.center.dx;
    final n = _rootCount();

    if (isUpper) {
      _drawRootLines(canvas, cx, cr.top, cr.top - rootHeight + 2, n, paint);
    } else {
      _drawRootLines(
          canvas, cx, cr.bottom, cr.bottom + rootHeight - 2, n, paint);
    }
  }

  int _rootCount() {
    switch (type) {
      case _ToothType.molar:
        return 3;
      case _ToothType.premolar:
        return 2;
      case _ToothType.canine:
      case _ToothType.incisor:
        return 1;
    }
  }

  void _drawRootLines(Canvas canvas, double cx, double base, double tip,
      int count, Paint paint) {
    final spread = crownWidth * 0.22;
    final mid = (base + tip) / 2;

    if (count == 1) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, base)
          ..quadraticBezierTo(cx - 0.8, mid, cx, tip),
        paint,
      );
    } else if (count == 2) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - spread * 0.2, base)
          ..quadraticBezierTo(cx - spread * 1.1, mid, cx - spread * 0.7, tip),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx + spread * 0.2, base)
          ..quadraticBezierTo(cx + spread * 1.1, mid, cx + spread * 0.7, tip),
        paint,
      );
    } else {
      // 3 roots (molar)
      canvas.drawPath(
        Path()
          ..moveTo(cx - spread * 0.5, base)
          ..quadraticBezierTo(
              cx - spread * 1.5, mid, cx - spread * 1.1, tip),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx, base)
          ..quadraticBezierTo(cx, mid, cx, tip),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx + spread * 0.5, base)
          ..quadraticBezierTo(
              cx + spread * 1.5, mid, cx + spread * 1.1, tip),
        paint,
      );
    }
  }

  // ── Internal curved division lines ────────────────────────

  void _drawInternalLines(Canvas canvas, Rect cr, Paint paint) {
    final tw = cr.width / 3;
    final th = cr.height / 3;
    const c = 2.0;

    _curveLine(canvas, cr.left, cr.top, cr.left + tw, cr.top + th, c, paint);
    _curveLine(
        canvas, cr.right, cr.top, cr.left + tw * 2, cr.top + th, -c, paint);
    _curveLine(
        canvas, cr.left, cr.bottom, cr.left + tw, cr.top + th * 2, c, paint);
    _curveLine(canvas, cr.right, cr.bottom, cr.left + tw * 2,
        cr.top + th * 2, -c, paint);
  }

  void _curveLine(Canvas canvas, double x1, double y1, double x2, double y2,
      double ctrl, Paint paint) {
    final mx = (x1 + x2) / 2 + ctrl;
    final my = (y1 + y2) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(mx, my, x2, y2),
      paint,
    );
  }

  // ── Face fill paths (5-zone layout) ───────────────────────

  void _drawFace(
      Canvas canvas, Path path, ToothCondition? condition, Color bg) {
    final color = condition != null ? conditionColor(condition) : bg;
    canvas.drawPath(
        path, Paint()..color = color..style = PaintingStyle.fill);
  }

  Path _vestibularPath(Rect cr) {
    final tw = cr.width / 3;
    final th = cr.height / 3;
    return Path()
      ..moveTo(cr.left, cr.top)
      ..lineTo(cr.right, cr.top)
      ..lineTo(cr.left + tw * 2, cr.top + th)
      ..lineTo(cr.left + tw, cr.top + th)
      ..close();
  }

  Path _mesialPath(Rect cr) {
    final tw = cr.width / 3;
    final th = cr.height / 3;
    return Path()
      ..moveTo(cr.left, cr.top)
      ..lineTo(cr.left + tw, cr.top + th)
      ..lineTo(cr.left + tw, cr.top + th * 2)
      ..lineTo(cr.left, cr.bottom)
      ..close();
  }

  Path _oclusalPath(Rect cr) {
    final tw = cr.width / 3;
    final th = cr.height / 3;
    return Path()
      ..moveTo(cr.left + tw, cr.top + th)
      ..lineTo(cr.left + tw * 2, cr.top + th)
      ..lineTo(cr.left + tw * 2, cr.top + th * 2)
      ..lineTo(cr.left + tw, cr.top + th * 2)
      ..close();
  }

  Path _distalPath(Rect cr) {
    final tw = cr.width / 3;
    final th = cr.height / 3;
    return Path()
      ..moveTo(cr.right, cr.top)
      ..lineTo(cr.right, cr.bottom)
      ..lineTo(cr.left + tw * 2, cr.top + th * 2)
      ..lineTo(cr.left + tw * 2, cr.top + th)
      ..close();
  }

  Path _lingualPath(Rect cr) {
    final tw = cr.width / 3;
    final th = cr.height / 3;
    return Path()
      ..moveTo(cr.left + tw, cr.top + th * 2)
      ..lineTo(cr.left + tw * 2, cr.top + th * 2)
      ..lineTo(cr.right, cr.bottom)
      ..lineTo(cr.left, cr.bottom)
      ..close();
  }

  void _drawExtraction(Canvas canvas, Rect cr) {
    final xPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(cr.left + 4, cr.top + 4),
      Offset(cr.right - 4, cr.bottom - 4),
      xPaint,
    );
    canvas.drawLine(
      Offset(cr.right - 4, cr.top + 4),
      Offset(cr.left + 4, cr.bottom - 4),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ToothPainter old) =>
      state != old.state ||
      borderColor != old.borderColor ||
      type != old.type;
}
