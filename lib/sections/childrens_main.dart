import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../widgets/child_card.dart';
import '../services/child_service.dart' as new_service;
import '../utils/child_service.dart' as old_service;
import '../config/api_config.dart';
import '../sections/writing_interface_section.dart';
import '../sections/assessment_report_section.dart';
import '../sections/pre_writing_section.dart';
import '../sections/sentence_section.dart';

class ChildrensMain extends StatefulWidget {
  final List children;
  final Function onRefresh;

  const ChildrensMain({
    super.key,
    this.children = const [],
    required this.onRefresh,
  });

  @override
  State<ChildrensMain> createState() => _ChildrensMainState();
}

class _ChildrensMainState extends State<ChildrensMain> {
  List<ChildProfile> childrenList = [];
  bool isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchChildren();
  }

  @override
  void didUpdateWidget(covariant ChildrensMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When parent passes new children list, refresh ours
    if (oldWidget.children.length != widget.children.length) {
      _fetchChildren();
    }
  }

  Future<void> _loadUserIdAndFetchChildren() async {
    final userId = await Config.getUserId();
    if (mounted) {
      setState(() {
        _userId = userId;
      });
      _fetchChildren();
    }
  }

  // Fetch children from backend using new service
  Future<void> _fetchChildren() async {
    if (_userId == null) return;
    
    setState(() {
      isLoading = true;
    });
    try {
      final children = await new_service.ChildService.getChildren(userId: _userId!);
      if (mounted) {
        setState(() {
          // Convert new_service.Child to old ChildProfile for compatibility
          childrenList = children.map((child) {
            return ChildProfile(
              id: child.childId,
              name: child.name,
              age: child.age.toString(),
              grade: 'Grade',
              avatar: child.name[0].toUpperCase(),
              lastAssessment: 'Not assessed',
              assessmentStatus: 'Pending',
            );
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading children: $e')),
        );
      }
    }
  }

  void _showAddChildDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Child Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Child Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Name is required';
                      if (v.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (1-18)',
                      prefixIcon: Icon(Icons.cake),
                      hintText: 'e.g., 8',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Age is required';
                      final age = int.tryParse(v);
                      if (age == null || age < 1 || age > 18) {
                        return 'Age must be between 1 and 18';
                      }
                      return null;
                    },
                    enabled: !isSubmitting,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isSubmitting = true;
                        });

                        try {
                          await new_service.ChildService.addChild(
                            userId: _userId ?? '',
                            name: nameCtrl.text.trim(),
                            age: int.parse(ageCtrl.text),
                            notes: '',
                          );

                          if (mounted) {
                            Navigator.of(ctx).pop();
                            _fetchChildren();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${nameCtrl.text} added successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Child'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      ageCtrl.dispose();
    });
  }

  void _deleteChild(String childId, String childName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Child Profile'),
        content: Text('Are you sure you want to delete $childName\'s profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await new_service.ChildService.deleteChild(childId: childId);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  _fetchChildren();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$childName removed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            const Text(
              'Childrens',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Child'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3748),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        if (isLoading)
          SizedBox(
            height: 400,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (childrenList.isEmpty)
          SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.child_care_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No children profiles yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add New Child" to create a profile',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 2.0,
            ),
            itemCount: childrenList.length,
            itemBuilder: (context, index) {
              final child = childrenList[index];
              return ChildCard(
                child: child,
                onDelete: () => _deleteChild(child.id, child.name),
                
                // Navigate to Assessment Report Section for this child
                onViewReport: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssessmentReportSection(
                        childId: child.id,
                      ),
                    ),
                  );
                },
                
                // Navigate to test section based on selection
                onStartTest: () {
                  _showTestTypeMenu(context, child);
                },
                
                // ==================== BACKEND NAVIGATION - UNCOMMENT WHEN READY ====================
                // onSchedule: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => AppointmentSection(),
                //     ),
                //   );
                // },
                // ===================================================================================
                
                // ==================== REMOVE THIS AFTER BACKEND CONNECTION ====================
                onSchedule: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Schedule session for ${child.name}'),
                    ),
                  );
                },
                // ==============================================================================
              );
            },
          ),
      ],
    );
  }

  void _showTestTypeMenu(BuildContext context, ChildProfile child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Test Type for ${child.name}'),
        content: const Text('Which assessment would you like to perform?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WritingInterfaceSection(
                    childId: child.id,
                    childName: child.name,
                  ),
                ),
              );
            },
            child: const Text('Writing Practice'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreWritingSection(
                    childId: child.id,
                    childName: child.name,
                  ),
                ),
              );
            },
            child: const Text('Pre-Writing Shapes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SentenceSection(
                    childId: child.id,
                    childName: child.name,
                  ),
                ),
              );
            },
            child: const Text('Sentence Writing'),
          ),
        ],
      ),
    );
  }
}