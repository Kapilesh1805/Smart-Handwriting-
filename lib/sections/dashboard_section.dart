import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';

class DashboardSection extends StatefulWidget {
  final List<Child> children;
  final Function onRefresh;

  const DashboardSection({
    super.key,
    this.children = const [],
    required this.onRefresh,
  });

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await Config.getUserId();
    if (mounted) {
      setState(() {
        _userId = userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Banner Section
        Container(
          height: 220.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE3E8F0)),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                const double cardHeight = 220.0;
                final double targetWidth = maxWidth * 0.60;
                final double width = targetWidth.clamp(280.0, 720.0);
                final double height = (cardHeight * 0.9).clamp(180.0, cardHeight);
                return SizedBox(
                  width: width,
                  height: height,
                  child: Image.asset(
                    'assets/images/floe_banner.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FC),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFE3E8F0)),
                        ),
                        child: const Text(
                          'Welcome to Smart Handwriting',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24.0),

        // Feature Cards
        Row(
          children: [
            FeatureCard(
              title: 'Add new\nchild profile',
              icon: Icons.child_care,
              onTap: () => _showAddChildDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 32.0),

        // Children List Section
        Text(
          'Your Children (${widget.children.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),

        if (widget.children.isEmpty)
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.child_care_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No children yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first child profile to get started',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final child = widget.children[index];
              return _buildChildCard(context, child);
            },
          ),
      ],
    );
  }

  /// Build child profile card with edit/delete options
  Widget _buildChildCard(BuildContext context, Child child) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE3E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Child Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                child.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16.0),

          // Child Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: ${child.age}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (child.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      child.notes.length > 50
                          ? '${child.notes.substring(0, 50)}...'
                          : child.notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Edit & Delete Buttons
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _showEditChildDialog(context, child),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => _showDeleteConfirmation(context, child),
          ),
        ],
      ),
    );
  }

  /// Add child dialog
  void _showAddChildDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Child'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Child name'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 2) return 'Min 2 characters';
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age (1-18)'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final age = int.tryParse(v);
                          if (age == null || age < 1 || age > 18) {
                            return 'Age must be 1-18';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                        maxLines: 3,
                        enabled: !isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isLoading = true);
                            try {
                              await ChildService.addChild(
                                userId: _userId ?? '',
                                name: nameCtrl.text,
                                age: int.parse(ageCtrl.text),
                                notes: notesCtrl.text,
                              );

                              if (mounted) {
                                Navigator.of(ctx).pop();
                                await widget.onRefresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${nameCtrl.text} added successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setDialogState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst('Exception: ', ''),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      ageCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  /// Edit child dialog
  void _showEditChildDialog(BuildContext context, Child child) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: child.name);
    final ageCtrl = TextEditingController(text: child.age.toString());
    final notesCtrl = TextEditingController(text: child.notes);
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Child'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Child name'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 2) return 'Min 2 characters';
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age (1-18)'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final age = int.tryParse(v);
                          if (age == null || age < 1 || age > 18) {
                            return 'Age must be 1-18';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                        maxLines: 3,
                        enabled: !isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isLoading = true);
                            try {
                              await ChildService.updateChild(
                                childId: child.childId,
                                name: nameCtrl.text,
                                age: int.parse(ageCtrl.text),
                                notes: notesCtrl.text,
                              );

                              if (mounted) {
                                Navigator.of(ctx).pop();
                                await widget.onRefresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Child updated successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setDialogState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst('Exception: ', ''),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      ageCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  /// Delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, Child child) {
    bool isLoading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Child'),
              content: Text(
                'Are you sure you want to delete ${child.name}? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);
                          try {
                            await ChildService.deleteChild(
                              childId: child.childId,
                            );

                            if (mounted) {
                              Navigator.of(ctx).pop();
                              await widget.onRefresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Child deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst('Exception: ', ''),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSavedAssessmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saved Assessments'),
        content: const Text('This will list saved assessments from backend.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGenerateReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate reports'),
        content: const Text(
          'Choose parameters and generate downloadable reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProgressAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Progress analytics'),
        content: const Text('Analytics and charts will appear here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}