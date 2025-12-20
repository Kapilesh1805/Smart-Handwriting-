import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../widgets/child_card.dart';
import '../utils/child_service.dart';
import '../sections/writing_interface_section.dart';
import '../sections/assessment_report_section.dart';

class ChildrensMain extends StatefulWidget {
  const ChildrensMain({super.key});

  @override
  State<ChildrensMain> createState() => _ChildrensMainState();
}

class _ChildrensMainState extends State<ChildrensMain> {
  List<ChildProfile> childrenList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  // Fetch children from backend
  Future<void> _fetchChildren() async {
    setState(() {
      isLoading = true;
    });
    try {
      final children = await ChildService.fetchChildren();
      if (mounted) {
        setState(() {
          childrenList = children;
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
    final gradeCtrl = TextEditingController();
    String? selectedAvatar;
    bool isSubmitting = false;

    final List<String> avatarOptions = [
      '👦',
      '👧',
      '🧒',
      '👶',
      '🧑',
      '👨',
      '👩',
      '🙂',
      '😊',
      '🌟',
    ];

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Child Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake),
                      hintText: 'e.g., 8',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Enter valid age';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: gradeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      prefixIcon: Icon(Icons.school),
                      hintText: 'e.g., Grade 2 or 2',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Choose Avatar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: avatarOptions.map((emoji) {
                      final isSelected = selectedAvatar == emoji;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedAvatar = emoji),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                          final child = await ChildService.addChild(
                            name: nameCtrl.text,
                            age: ageCtrl.text,
                            grade: gradeCtrl.text,
                            avatar: selectedAvatar ?? '👦',
                          );

                          if (mounted) {
                            setState(() {
                              childrenList.add(child);
                            });
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${nameCtrl.text} added successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                          setDialogState(() {
                            isSubmitting = false;
                          });
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
      gradeCtrl.dispose();
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
                await ChildService.deleteChild(childId);
                if (mounted) {
                  setState(() {
                    childrenList.removeWhere((child) => child.id == childId);
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$childName removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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
                
                // Navigate to Writing Interface Section for this child
                onStartTest: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WritingInterfaceSection(),
                    ),
                  );
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
}