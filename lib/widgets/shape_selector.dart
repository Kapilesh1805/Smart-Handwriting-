import 'package:flutter/material.dart';
import '../models/pre_writing_shape.dart';
import '../utils/drawing_service.dart';

class ShapeSelector extends StatelessWidget {
  final PreWritingShape selectedShape;
  final Function(PreWritingShape) onShapeSelected;

  const ShapeSelector({
    super.key,
    required this.selectedShape,
    required this.onShapeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final shapes = DrawingService.getShapes();

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Shapes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: shapes.map((shape) => _buildShapeButton(shape)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeButton(PreWritingShape shape) {
    final isSelected = selectedShape.id == shape.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onShapeSelected(shape),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(
                shape.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                shape.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}