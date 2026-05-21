import 'package:flutter/material.dart';

class DropZone extends StatelessWidget {
  final bool isDragOver;
  final VoidCallback onTap;

  const DropZone({super.key, required this.isDragOver, required this.onTap});

  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 380,
            height: 180,
            decoration: BoxDecoration(
              color: isDragOver
                  ? const Color(0xFF1D9E75).withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDragOver ? const Color(0xFF1D9E75) : const Color(0xFFD3D1C7),
                width: isDragOver ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file_outlined,
                    size: 40,
                    color: isDragOver ? const Color(0xFF1D9E75) : Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Keo tha file .txt vao day',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('hoac nhan de chon file',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          ),
        ),
      );
}
