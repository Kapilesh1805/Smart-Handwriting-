import 'package:flutter/material.dart';

class DrawingToolsWidget extends StatelessWidget {
  final String selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final Function(String) onToolChanged;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;
  final VoidCallback onClear;
  final VoidCallback onSave;

  const DrawingToolsWidget({
    super.key,
    required this.selectedTool,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.grey[850],
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Pen Tool
          _ToolButton(
            icon: Icons.edit,
            isSelected: selectedTool == 'pen',
            onTap: () => onToolChanged('pen'),
            tooltip: 'Pen',
          ),
          const SizedBox(height: 12),
          // Line Tool
          _ToolButton(
            icon: Icons.straighten,
            isSelected: selectedTool == 'line',
            onTap: () => onToolChanged('line'),
            tooltip: 'Line',
          ),
          const SizedBox(height: 12),
          // Curve Tool
          _ToolButton(
            icon: Icons.waves,
            isSelected: selectedTool == 'curve',
            onTap: () => onToolChanged('curve'),
            tooltip: 'Curve',
          ),
          const SizedBox(height: 12),
          // Circle Tool
          _ToolButton(
            icon: Icons.circle_outlined,
            isSelected: selectedTool == 'circle',
            onTap: () => onToolChanged('circle'),
            tooltip: 'Circle',
          ),
          const SizedBox(height: 12),
          // Triangle Tool
          _ToolButton(
            icon: Icons.change_history,
            isSelected: selectedTool == 'triangle',
            onTap: () => onToolChanged('triangle'),
            tooltip: 'Triangle',
          ),
          const SizedBox(height: 24),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[700],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const SizedBox(height: 12),
          // Eraser
          _ToolButton(
            icon: Icons.cleaning_services,
            isSelected: selectedTool == 'eraser',
            onTap: () => onToolChanged('eraser'),
            tooltip: 'Eraser',
          ),
          const SizedBox(height: 12),
          // Delete All
          _ToolButton(
            icon: Icons.delete_outline,
            isSelected: false,
            onTap: onClear,
            tooltip: 'Clear',
          ),
          const SizedBox(height: 12),
          // Sound/Speaker
          _ToolButton(
            icon: Icons.volume_up,
            isSelected: false,
            onTap: () {
              // API CONNECTION: Play pronunciation/instructions
              // GET /api/audio/pre-writing-guide
            },
            tooltip: 'Sound',
          ),
          const Spacer(),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[700],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const SizedBox(height: 12),
          // Save Button
          GestureDetector(
            onTap: onSave,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.save,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _ToolButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.orange, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}