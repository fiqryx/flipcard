import 'dart:io';
import 'package:flipcard/constants/enums.dart';
import 'package:flipcard/constants/extensions.dart';
import 'package:flipcard/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flipcard/widgets/heatmap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flipcard/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late UserStore _userStore;
  final _picker = ImagePicker();
  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  int _tabIndex = 0;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (image == null || !mounted) {
      return;
    }

    try {
      setState(() => _isLoading = true);

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

      if (croppedFile != null && _userStore.user != null) {
        final imageUrl = await UserService.uploadImage(
          File(croppedFile.path),
          currentImageUrl: _userStore.user?.imageUrl,
        );

        final user = _userStore.user!.copyWith(imageUrl: imageUrl);
        await UserService.save(user);
        _userStore.updateUser(user);
      }
    } catch (e) {
      _showToast(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser(User updated) async {
    try {
      setState(() => _isLoading = true);

      await UserService.save(updated);
      _userStore.updateUser(updated);

      if (mounted) {
        showFToast(
          context: context,
          title: Text('Updated successfully!'),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } catch (e) {
      _showToast(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    Navigator.pop(context);
    try {
      await UserService.signOut();
      await _storage.delete(key: 'logged');
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);

        _userStore.reset();
        _showToast('Signed out successfully');
      }
    } catch (e) {
      _showToast("Sign out failed: ${e.toString()}");
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a name';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }

    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }

    if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
      return 'Number too short';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }

    // Basic email regex validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null; // Valid email
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    // Password strength validation
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number';
    }

    return null; // Valid password
  }

  String? _validateBirth(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    final minDate = DateTime.now().subtract(
      const Duration(days: 365 * 10 + 2),
    ); // 10 years ago (+2 days for leap years)
    if (date.isAfter(minDate)) {
      return 'Must be at least 10 years ago';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final user = _userStore.user;
    final provider = UserService.provider ?? '';

    if (user == null || _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            elevation: 10.0,
            expandedHeight: 200,
            collapsedHeight: 100,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (_, _) => Stack(
                children: [
                  Positioned.fill(
                    child: Material(
                      elevation: 0, // increase to show the shadow
                      borderRadius: BorderRadius.circular(16),
                      color: colors.secondary,
                      child: Container(),
                    ),
                  ),
                  FlexibleSpaceBar(
                    centerTitle: true,
                    collapseMode: CollapseMode.parallax,
                    stretchModes: [StretchMode.zoomBackground],
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _showImagePreview,
                              child: FAvatar(
                                size: 52,
                                style: (style) => style.copyWith(
                                  backgroundColor: colors.mutedForeground
                                      .withValues(alpha: 0.2),
                                  foregroundColor: colors.primaryForeground,
                                ),
                                image: NetworkImage(user.imageUrl ?? ''),
                                fallback: Icon(
                                  Icons.person,
                                  size: 20,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 2,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 10,
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: colors.primaryForeground,
                                  ),
                                  onPressed: !_isLoading ? _uploadImage : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          user.name,
                          style: theme.typography.sm.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: theme.typography.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: FTabs(
                initialIndex: _tabIndex,
                onChange: (idx) => setState(() => _tabIndex = idx),
                children: [
                  // Statistics
                  FTabEntry(
                    label: Text('Statistics'),
                    child: Column(
                      children: [
                        if (_userStore.user != null) ...[
                          // Overview
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: _ProfileStatisticsGrid(
                              userStore: _userStore,
                            ),
                          ),
                          SizedBox(height: 10),

                          // Recent Activity
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: FCard(child: _ProfileActivity()),
                          ),
                        ] else ...[
                          Center(
                            child: Text(
                              'No statistics available',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Account
                  FTabEntry(
                    label: Text('Account'),
                    child: Column(
                      spacing: 12,
                      children: [
                        FTileGroup(
                          style: (style) => style.copyWith(
                            childPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          children: [
                            FTile(
                              title: const Text('Name'),
                              details: Text(user.name),
                              suffix: Icon(FIcons.chevronRight),
                              onPress: () => _showEditSheet(
                                title: 'Edit Name',
                                type: InputType.textField,
                                initialValue: user.name,
                                label: 'Full Name',
                                validator: _validateName,
                                onSave: (value) =>
                                    _updateUser(user.copyWith(name: value)),
                              ),
                            ),
                          ],
                        ),
                        FTileGroup(
                          style: (style) => style.copyWith(
                            childPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          children: [
                            FTile(
                              title: const Text('Gender'),
                              details: Text(user.gender?.capitalize() ?? ''),
                              suffix: Icon(FIcons.chevronRight),
                              onPress: () => _showEditSheet(
                                title: 'Select Gender',
                                type: InputType.selection,
                                initialValue: user.gender,
                                options: [
                                  'male',
                                  'female',
                                  'other',
                                  'prefer not to say',
                                ],
                                onSave: (value) =>
                                    _updateUser(user.copyWith(gender: value)),
                              ),
                            ),
                            FTile(
                              title: const Text('Date of birth'),
                              details: Text(user.birthDate?.format() ?? ''),
                              suffix: Icon(FIcons.chevronRight),
                              onPress: () => _showEditSheet(
                                title: 'Select Date of Birth',
                                type: InputType.datePicker,
                                initialDate: user.birthDate,
                                validatorDate: _validateBirth,
                                onSave: (value) => _updateUser(
                                  user.copyWith(birthDate: value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        FTileGroup(
                          style: (style) => style.copyWith(
                            childPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          children: [
                            FTile(
                              title: const Text('Phone number'),
                              details: Text(user.phone ?? ''),
                              suffix: Icon(FIcons.chevronRight),
                              onPress: () => _showEditSheet(
                                title: 'Edit Phone Number',
                                type: InputType.textField,
                                label: 'Phone Number',
                                initialValue: user.phone,
                                keyboardType: TextInputType.phone,
                                validator: _validatePhone,
                                onSave: (value) =>
                                    _updateUser(user.copyWith(phone: value)),
                              ),
                            ),
                            FTile(
                              enabled: provider == "email",
                              title: const Text('Email'),
                              details: Text(user.email),
                              suffix: Icon(FIcons.chevronRight),
                              onPress: () => _showEditSheet(
                                title: 'Edit Email',
                                type: InputType.textField,
                                initialValue: user.email,
                                label: 'Email Address',
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                onSave: (value) => debugPrint(value),
                              ),
                            ),
                          ],
                        ),
                        FTileGroup(
                          style: (style) => style.copyWith(
                            childPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          children: [
                            if (provider == 'email')
                              FTile(
                                title: Text('Change Password'),
                                suffix: Icon(FIcons.chevronRight),
                                onPress: () => _showEditSheet(
                                  title: 'Change Password',
                                  type: InputType.passwordChange,
                                  validator: _validatePassword,
                                  onSave: (value) => debugPrint(value),
                                ),
                              ),
                            if (provider != 'email')
                              FTile(
                                enabled: false,
                                title: Text('Account type'),
                                details: Text(provider.capitalize()),
                                suffix: Icon(FIcons.chevronRight),
                              ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: FButton(
                            style: FButtonStyle.destructive(),
                            onPress: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    _SignOutDialog(onSignOut: _signOut),
                              );
                            },
                            prefix: Icon(FIcons.logOut),
                            child: Text("Sign Out"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview() {
    final user = _userStore.user;
    ImageProvider? imageProvider;

    if (user?.imageUrl != null && user!.imageUrl!.isNotEmpty) {
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

  void _showEditSheet({
    required String title,
    required InputType type,
    required Function(dynamic) onSave,
    String? initialValue,
    String? label,
    List<String>? options,
    DateTime? initialDate,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? Function(DateTime?)? validatorDate,
  }) async {
    await showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (context) => _EditProfileSheet(
        title: title,
        type: type,
        initialValue: initialValue,
        label: label,
        options: options,
        initialDate: initialDate,
        keyboardType: keyboardType,
        onSave: onSave,
        validator: validator,
        validatorDate: validatorDate,
      ),
    );
  }

  void _showToast(String message) {
    showFToast(
      context: context,
      title: Text(message.toString().replaceAll('Exception: ', '')),
      alignment: FToastAlignment.bottomCenter,
    );
  }
}

class _ProfileStatisticsGrid extends StatelessWidget {
  final UserStore userStore;

  const _ProfileStatisticsGrid({required this.userStore});

  @override
  Widget build(BuildContext context) {
    final totalDecks = userStore.user?.totalDecks ?? 0;
    final totalCards = userStore.user?.totalCards ?? 0;
    final totalQuizzes = userStore.quiz.length;
    final accuracy = userStore.stats?.average ?? 0;
    final currentStreak = _calculateCurrentStreak();
    final longestStreak = _calculateLongestStreak();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              title: 'Total Decks',
              value: totalDecks.toString(),
              icon: FIcons.layers,
              color: Colors.purple,
            ),
            _StatCard(
              title: 'Total Cards',
              value: totalCards.toString(),
              icon: Icons.quiz,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Quiz Completed',
              value: totalQuizzes.toString(),
              icon: Icons.video_library,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Accuracy',
              value: '${accuracy.toStringAsFixed(1)}%',
              icon: FIcons.target,
              color: accuracy > 70 ? Colors.green : Colors.red,
            ),
            _StatCard(
              title: 'Current Streak',
              value: currentStreak.toString(),
              subtitle: currentStreak == 1 ? 'day' : 'days',
              icon: Icons.local_fire_department,
              color: Colors.deepOrange,
            ),
            _StatCard(
              title: 'Best Streak',
              value: longestStreak.toString(),
              subtitle: longestStreak == 1 ? 'day' : 'days',
              icon: Icons.emoji_events,
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  int _calculateCurrentStreak() {
    if (userStore.quiz.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Get unique quiz dates (only date part, not time)
    final quizDates =
        userStore.quiz
            .map((quiz) {
              final date = quiz.completedAt;
              return DateTime(date.year, date.month, date.day);
            })
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // Sort in descending order

    if (quizDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = today;

    // Check if there's a quiz today, if not check yesterday
    if (!quizDates.contains(today)) {
      if (!quizDates.contains(yesterday)) {
        return 0;
      }
      checkDate = yesterday;
    }

    // Count consecutive days
    for (final date in quizDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreak() {
    if (userStore.quiz.isEmpty) return 0;

    // Get unique quiz dates
    final quizDates =
        userStore.quiz
            .map((quiz) {
              final date = quiz.completedAt;
              return DateTime(date.year, date.month, date.day);
            })
            .toSet()
            .toList()
          ..sort();

    if (quizDates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < quizDates.length; i++) {
      final previousDate = quizDates[i - 1];
      final currentDate = quizDates[i];
      final dayDifference = currentDate.difference(previousDate).inDays;

      if (dayDifference == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak
            ? currentStreak
            : longestStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        FCard(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.xs.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 32, color: color),
            ],
          ),
        ),
        Positioned(
          left: 20,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                value,
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.foreground,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.typography.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileActivity extends StatefulWidget {
  const _ProfileActivity();

  @override
  State<_ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<_ProfileActivity> {
  late UserStore _userStore;

  final TimePeriod _fixedPeriod = TimePeriod.months6;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Auto-scroll to current date after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure the scroll controller is fully initialized
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollToCurrentDate();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  void _scrollToCurrentDate() {
    if (!_scrollController.hasClients) return;

    // Calculate the total width of the scrollable heatmap content (without day labels)
    final heatmapWidth =
        _getHeatmapWidth(_fixedPeriod) - 30.0; // Subtract label width

    // Get the viewport width (available width for scrolling)
    final viewportWidth =
        MediaQuery.of(context).size.width - 30.0; // Subtract label width

    // Calculate position to show the last few weeks (current date area)
    // We want to show the current week towards the right side of the viewport
    final targetPosition = heatmapWidth - viewportWidth + (viewportWidth * 0.2);

    // Get the actual maximum scroll extent from the scroll controller
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // Ensure we don't scroll beyond the available scroll extent
    final scrollPosition = targetPosition.clamp(0.0, maxScrollExtent);

    // Only scroll if there's actually content to scroll
    if (maxScrollExtent > 0) {
      _scrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final heatmapData = _generateHeatmapData(_fixedPeriod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity',
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track your progress throughout the year',
              style: theme.typography.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Content
        SizedBox(
          height: _getHeatmapHeight(_fixedPeriod),
          child: Row(
            children: [
              // Sticky day labels
              SizedBox(
                width: 30.0,
                child: CustomPaint(
                  painter: DayLabels(
                    theme: theme,
                    cellSize: 14.0,
                    monthLabelHeight: _fixedPeriod.days > 84 ? 20.0 : 0.0,
                  ),
                  size: Size(30.0, _getHeatmapHeight(_fixedPeriod)),
                ),
              ),
              // Scrollable heatmap content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width:
                        _getHeatmapWidth(_fixedPeriod) -
                        30.0, // Subtract label width
                    child: CustomPaint(
                      painter: Heatmap(
                        data: heatmapData,
                        theme: theme,
                        timePeriod: _fixedPeriod,
                        cellSize: 14.0,
                      ),
                      size: Size(
                        _getHeatmapWidth(_fixedPeriod) - 30.0,
                        _getHeatmapHeight(_fixedPeriod),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getTotalQuizzesInPeriod(_fixedPeriod)} completed in the last year',
              style: theme.typography.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            Row(
              children: [
                Text(
                  'Less',
                  style: theme.typography.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                SizedBox(width: 4),
                ...List.generate(5, (index) {
                  return Container(
                    width: 10,
                    height: 10,
                    margin: EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(index),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                SizedBox(width: 4),
                Text(
                  'More',
                  style: theme.typography.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  double _getHeatmapWidth(TimePeriod period) {
    const cellSize = 14.0;
    const cellPadding = 2.0;
    const labelWidth = 30.0;
    final totalWeeks = (period.days / 7).ceil();

    return labelWidth + (totalWeeks * (cellSize + cellPadding)) - cellPadding;
  }

  double _getHeatmapHeight(TimePeriod period) {
    const cellSize = 14.0;
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
    for (final quiz in _userStore.quiz) {
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

    return _userStore.quiz
        .where((quiz) => quiz.completedAt.isAfter(startDate))
        .length;
  }

  Color _getIntensityColor(int intensity) {
    final colors = context.theme.colors;
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

class _EditProfileSheet extends StatefulWidget {
  final String title;
  final InputType type;
  final String? initialValue;
  final String? label;
  final List<String>? options;
  final DateTime? initialDate;
  final TextInputType? keyboardType;
  final Function(dynamic) onSave;
  final String? Function(String?)? validator;
  final String? Function(DateTime?)? validatorDate;

  const _EditProfileSheet({
    required this.title,
    required this.type,
    required this.onSave,
    this.initialValue,
    this.label,
    this.options,
    this.initialDate,
    this.keyboardType,
    this.validator,
    this.validatorDate,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _textController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late final _calendarController = FDateFieldController(
    vsync: this,
    validator: widget.validatorDate ?? (value) => null,
    initialDate: widget.initialDate ?? DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    switch (widget.type) {
      case InputType.textField:
        return FTextFormField(
          autofocus: true,
          controller: _textController,
          label: Text(widget.label ?? 'Value'),
          keyboardType: widget.keyboardType,
          validator: widget.validator,
        );

      case InputType.selection:
        return Column(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children:
              widget.options
                  ?.map(
                    (option) => FTile(
                      title: Text(option.capitalize()),
                      suffix: _textController.text == option
                          ? Icon(Icons.check_circle)
                          : null,
                      onPress: () {
                        widget.onSave(option);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList() ??
              [],
        );

      case InputType.datePicker:
        return FDateField.calendar(controller: _calendarController);

      case InputType.passwordChange:
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            FTextFormField(
              validator: widget.validator,
              controller: _newPasswordController,
              label: Text('New Password'),
              obscureText: true,
            ),
            FTextFormField(
              controller: _confirmPasswordController,
              label: Text('Confirm New Password'),
              obscureText: true,
              validator: (value) => _newPasswordController.text == value
                  ? null
                  : 'Password confirmation not match',
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    // Selection and date picker handle their own actions
    if (widget.type == InputType.selection) {
      return [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ];
    }

    return [
      Expanded(
        child: FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: FButton(
          onPress: () {
            if (!_formKey.currentState!.validate()) return;

            dynamic value;

            if (widget.type == InputType.passwordChange) {
              value = {
                'current': _currentPasswordController.text,
                'new': _newPasswordController.text,
                'confirm': _confirmPasswordController.text,
              };
            } else if (widget.type == InputType.datePicker) {
              value = _calendarController.value;
            } else {
              value = _textController.text;
            }

            widget.onSave(value);
            Navigator.pop(context);
          },
          child: Text(
            widget.type == InputType.passwordChange ? 'Change' : 'Save',
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildContent(),
            const SizedBox(height: 24),
            Row(children: _buildActions()),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
