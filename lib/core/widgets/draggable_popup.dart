
//lib/core/widgets/draggable_popup.dart هذا الكود 
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

class DraggablePopup extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double? width;

  const DraggablePopup({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.width,
  });

  @override
  State<DraggablePopup> createState() => _DraggablePopupState();
}

class _DraggablePopupState extends State<DraggablePopup> {
  Offset _offset = Offset.zero; // لتخزين إحداثيات التحريك

  @override
  Widget build(BuildContext context) {
    // نستخدم Dialog لضمان التوسط والتعتيم الخلفي
    return Dialog(
      backgroundColor: Colors.transparent, // شفافية للسماح بشكلنا الخاص
      insetPadding: const EdgeInsets.all(20), // هوامش من الحواف
      child: Transform.translate(
        offset: _offset, // تطبيق الحركة
        child: SizedBox(
          width: widget.width ?? 500, // عرض افتراضي مناسب للديسك توب
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === شريط العنوان (منطقة التحريك) ===
                GestureDetector(
                  // هنا يكمن السحر: عند سحب الشريط، نحدث الإحداثيات
                  onPanUpdate: (details) {
                    setState(() {
                      _offset += details.delta;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.kDarkBrown,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // أيقونة السحب (مؤشر بصري)
                        const Icon(Icons.drag_indicator, color: Colors.white54, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // زر الإغلاق
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.onClose ?? () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // === محتوى النافذة ===
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: widget.child,
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