// FileName: lib/core/widgets/draggable_popup.dart
// Revision: 2.0 (Final Structural Standard - Ant Design Style)
// Date: 2025-12-19

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class DraggablePopup extends StatefulWidget {
  final String title;
  final Widget content; // الاسم الجديد ليعبر عن المحتوى فقط
  final List<Widget>? actions; // مكان مخصص للأزرار السفلية
  final VoidCallback? onClose; // أبقينا عليها للمرونة
  final double width;

  const DraggablePopup({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.onClose,
    this.width = 600,
  });

  @override
  State<DraggablePopup> createState() => _DraggablePopupState();
}

class _DraggablePopupState extends State<DraggablePopup> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Transform.translate(
        offset: _offset,
        child: GestureDetector(
          onTap: () {}, 
          child: Container(
            width: widget.width,
            constraints: const BoxConstraints(maxHeight: 800),
            decoration: BoxDecoration(
              color: AppTheme.kWhite,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: AppTheme.kBorder, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === 1. Header (Draggable) ===
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _offset += details.delta;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.kDarkBrown,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(7),
                        topRight: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.drag_indicator, color: AppTheme.kLightBeige, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: widget.onClose ?? () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

                // === 2. Content Body ===
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: widget.content, // استخدام content
                  ),
                ),

                // === 3. Actions Footer (Optional) ===
                if (widget.actions != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.kBorder)),
                      color: AppTheme.kOffWhite,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: widget.actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}