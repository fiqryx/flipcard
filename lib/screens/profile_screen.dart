import 'dart:io';
import 'package:flipcard/widgets/chart.dart';
import 'package:flipcard/widgets/heatmap.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flipcard/models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flipcard/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserStore _userStore;
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
    if (_nameController.text.isEmpty &&
        _emailController.text.isEmpty &&
        _userStore.user != null) {
      _nameController.text = _userStore.user!.name;
      _emailController.text = _userStore.user!.email;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _userStore.getData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (image != null) {
      await _cropImage(File(image.path));
    }
  }

  Future<void> _cropImage(File image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: context.theme.colors.background,
          toolbarWidgetColor: context.theme.colors.foreground,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
      final profile = User(
        id: _userStore.user?.id ?? '',
        userId: _userStore.user?.userId ?? '',
        name: _nameController.text,
        email: _emailController.text,
        totalDecks: _userStore.user?.totalDecks ?? 0,
        totalCards: _userStore.user?.totalCards ?? 0,
      );

      try {
        setState(() => _isSaving = true);

        if (_selectedImage != null) {
          final imageUrl = await UserService.uploadImage(_selectedImage!);
          profile.imageUrl = imageUrl;
        }

        await UserService.save(profile);
        _userStore.updateUser(profile);
        _toggleEdit();

        if (mounted) {
          showFToast(
            context: context,
            title: Text('Profile updated successfully!'),
            alignment: FToastAlignment.bottomCenter,
          );
        }
      } catch (e) {
        if (mounted) {
          showFToast(
            context: context,
            title: Text(e.toString().replaceAll('Exception: ', '')),
            alignment: FToastAlignment.bottomCenter,
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    Navigator.pop(context);
    try {
      await UserService.signOut();
      _userStore.reset();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        showFToast(
          context: context,
          title: Text("Signed out successfully"),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          title: Text("Sign out failed: ${e.toString()}"),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);
    final user = _userStore.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          if (_userStore.user != null)
            IconButton(
              icon: Icon(Icons.logout, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => _SignOutDialog(onSignOut: _signOut),
                );
              },
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Card
                    Card(
                      elevation: 0,
                      color: colors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colors.border, width: 1),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Profile Image Section
                                SizedBox(height: 10),
                                Center(
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: _showImagePreview,
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: colors.muted,
                                          backgroundImage:
                                              _selectedImage != null
                                              ? FileImage(_selectedImage!)
                                              : (user?.imageUrl != null &&
                                                        user!
                                                            .imageUrl!
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                        user.imageUrl!,
                                                      )
                                                    : null),
                                          child:
                                              _selectedImage == null &&
                                                  (user?.imageUrl == null ||
                                                      user!.imageUrl!.isEmpty)
                                              ? Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: colors.mutedForeground,
                                                )
                                              : null,
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: colors.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 2,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              iconSize: 16,
                                              icon: Icon(
                                                Icons.camera_alt,
                                                color: colors.primaryForeground,
                                              ),
                                              onPressed: _pickImage,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),

                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    enabled: _isEditing,
                                    prefixIcon: Icon(FIcons.user),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  enabled: false,
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    enabled: false,
                                    labelText: 'Email',
                                    prefixIcon: Icon(FIcons.mail),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                if (_isEditing) ...[
                                  SizedBox(height: 20),
                                  FButton(
                                    onPress: _saveProfile,
                                    child: _isSaving
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: colors.background,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text('Save Changes'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: FButton.icon(
                              onPress: _toggleEdit,
                              style: FButtonStyle.ghost(),
                              child: Icon(
                                _isEditing ? Icons.close : Icons.edit,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Statistics Chart Section
                    if (_userStore.user != null) ...[
                      Text(
                        'Statistics',
                        style: themeOf.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Card(
                        elevation: 0,
                        color: colors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: _ProfileStatistic(userStore: _userStore),
                        ),
                      ),
                      SizedBox(height: 10),
                      Card(
                        elevation: 0,
                        color: colors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: _ProfileActivity(userStore: _userStore),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedImage = null;
      }
    });
  }

  void _showImagePreview() {
    final user = _userStore.user;
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (user?.imageUrl != null && user!.imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(user.imageUrl!);
    }

    if (imageProvider != null) {
      showDialog(
        context: context,
        builder: (context) =>
            _ImagePreviewDialog(imageProvider: imageProvider!),
      );
    }
  }
}

class _ProfileStatistic extends StatelessWidget {
  final UserStore userStore;

  const _ProfileStatistic({required this.userStore});

  @override
  Widget build(BuildContext context) {
    final totalDecks = userStore.user?.totalDecks ?? 0;
    final totalCards = userStore.user?.totalCards ?? 0;
    final totalQuizzes = userStore.quiz.length;
    final accuracy = userStore.stats?.average ?? 0;

    // chart data for radial display (only accuracy)
    final chartData = [
      ChartData(
        label: 'Accuracy',
        value: accuracy,
        color: accuracy > 50
            ? Colors.tealAccent.shade700
            : Colors.redAccent.shade700,
        maxValue: 100,
      ),
    ];

    // legend data including all information
    final legendData = [
      ChartData(
        label: 'Decks',
        value: totalDecks.toDouble(),
        color: Colors.purpleAccent.shade700,
        maxValue: 100,
      ),
      ChartData(
        label: 'Cards',
        value: totalCards.toDouble(),
        color: Colors.indigoAccent.shade700,
        maxValue: 500,
      ),
      ChartData(
        label: 'Quizzes',
        value: totalQuizzes.toDouble(),
        color: Colors.amberAccent.shade700,
        maxValue: 50,
      ),
      ChartData(
        label: 'Accuracy',
        value: accuracy,
        color: accuracy > 50
            ? Colors.tealAccent.shade700
            : Colors.redAccent.shade700,
        maxValue: 100,
      ),
    ];

    return Column(
      children: [
        // Radial Chart
        SizedBox(
          height: 240,
          child: CustomPaint(
            painter: RadialChart(
              data: chartData,
              accuracyPercent: accuracy,
              theme: context.theme,
            ),
            size: Size.infinite,
          ),
        ),
        SizedBox(height: 20),

        // Legend (separate from chart) - includes accuracy for information
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: legendData.map((data) {
            return Legend(
              color: data.color,
              label: data.label,
              value: data.label == 'Accuracy'
                  ? '${data.value.toStringAsFixed(1)}%'
                  : data.value.toInt().toString(),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProfileActivity extends StatefulWidget {
  final UserStore userStore;

  const _ProfileActivity({required this.userStore});

  @override
  State<_ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<_ProfileActivity> {
  TimePeriod _selectedPeriod = TimePeriod.weeks12;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final heatmapData = _generateHeatmapData(_selectedPeriod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with time period selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quiz Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            // Time period dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<TimePeriod>(
                value: _selectedPeriod,
                underline: SizedBox(),
                isDense: true,
                style: TextStyle(fontSize: 12, color: colors.foreground),
                items: TimePeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Activity summary
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Text(
            //   _selectedPeriod.displayName.toLowerCase(),
            //   style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            // ),
            Text(
              '${_getTotalQuizzesInPeriod(_selectedPeriod)} completed',
              style: TextStyle(fontSize: 12, color: colors.mutedForeground),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Responsive calendar heatmap
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate cell size based on available width
            final totalWeeks = (_selectedPeriod.days / 7).ceil();
            final cellSize = _calculateCellSize(
              constraints.maxWidth,
              totalWeeks,
            );

            return SizedBox(
              height: _getHeatmapHeight(_selectedPeriod, cellSize),
              width: double.infinity,
              child: CustomPaint(
                painter: Heatmap(
                  data: heatmapData,
                  theme: theme,
                  timePeriod: _selectedPeriod,
                  cellSize: cellSize,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
        SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLegendStartText(_selectedPeriod),
              style: TextStyle(fontSize: 12, color: colors.mutedForeground),
            ),
            Row(
              children: [
                Text(
                  'Less',
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
                SizedBox(width: 4),
                ...List.generate(5, (index) {
                  return Container(
                    width: 10,
                    height: 10,
                    margin: EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(index, colors),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                SizedBox(width: 4),
                Text(
                  'More',
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  double _calculateCellSize(double maxWidth, int totalWeeks) {
    final labelWidth = 30.0;
    final availableWidth = maxWidth - labelWidth;
    const minCellSize = 8.0;
    const maxCellSize = 16.0;
    const cellPadding = 2.0;

    // Calculate cell size based on available width
    final calculatedSize =
        (availableWidth - (totalWeeks - 1) * cellPadding) / totalWeeks;
    return calculatedSize.clamp(minCellSize, maxCellSize);
  }

  double _getHeatmapHeight(TimePeriod period, double cellSize) {
    const cellPadding = 2.0;
    const dayLabelHeight = 20.0;
    const monthLabelHeight = 20.0;

    final hasMonthLabels = period.days > 84;
    final totalHeight = (7 * (cellSize + cellPadding)) - cellPadding;

    return totalHeight +
        (hasMonthLabels ? monthLabelHeight : 0) +
        dayLabelHeight;
  }

  List<Day> _generateHeatmapData(TimePeriod period) {
    final now = DateTime.now();
    final days = period.days;
    final startDate = now.subtract(Duration(days: days));
    final data = <Day>[];

    // Create a map of quiz counts by date
    final quizCounts = <String, int>{};
    for (final quiz in widget.userStore.quiz) {
      if (quiz.completedAt.isAfter(startDate)) {
        final dateKey = _formatDateKey(quiz.completedAt);
        quizCounts[dateKey] = (quizCounts[dateKey] ?? 0) + 1;
      }
    }

    // Generate data for each day
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = _formatDateKey(date);
      final count = quizCounts[dateKey] ?? 0;

      data.add(
        Day(date: date, count: count, intensity: _calculateIntensity(count)),
      );
    }

    return data;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateIntensity(int count) {
    if (count == 0) return 0;
    if (count <= 2) return 1;
    if (count <= 4) return 2;
    if (count <= 6) return 3;
    return 4;
  }

  int _getTotalQuizzesInPeriod(TimePeriod period) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: period.days));

    return widget.userStore.quiz
        .where((quiz) => quiz.completedAt.isAfter(startDate))
        .length;
  }

  String _getLegendStartText(TimePeriod period) {
    switch (period) {
      case TimePeriod.weeks4:
        return '4 weeks ago';
      case TimePeriod.weeks12:
        return '12 weeks ago';
      case TimePeriod.months3:
        return '3 months ago';
      case TimePeriod.months6:
        return '6 months ago';
      // case TimePeriod.year1:
      //   return '1 year ago';
    }
  }

  Color _getIntensityColor(int intensity, dynamic colors) {
    switch (intensity) {
      case 0:
        return colors.border;
      case 1:
        return Colors.green.shade200;
      case 2:
        return Colors.green.shade400;
      case 3:
        return Colors.green.shade600;
      case 4:
        return Colors.green.shade800;
      default:
        return colors.border;
    }
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  final ImageProvider imageProvider;

  const _ImagePreviewDialog({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping the image
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),

          // close button
          // Positioned(
          //   top: 0,
          //   right: 0,
          //   child: IconButton(
          //     onPressed: () => Navigator.of(context).pop(),
          //     icon: Container(
          //       padding: EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: Colors.black54,
          //         shape: BoxShape.circle,
          //       ),
          //       child: Icon(Icons.close, color: Colors.white, size: 24),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _SignOutDialog extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SignOutDialog({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(
        'Are you sure you want to sign out?',
        style: TextStyle(color: context.theme.colors.mutedForeground),
      ),
      actions: [
        FButton(
          mainAxisSize: MainAxisSize.min,
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.outline(),
          child: Text('Cancel'),
        ),
        FButton(
          mainAxisSize: MainAxisSize.min,
          style: FButtonStyle.destructive(),
          onPress: onSignOut,
          child: Text('Sign Out'),
        ),
      ],
    );
  }
}
