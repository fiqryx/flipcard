import 'dart:math';

import 'package:flipcard/constants/storage.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  final _key = 'setup_permission';

  late UserStore _userStore;
  late AnimationController _headerAnimationController;
  late AnimationController _iconRotationController;
  late AnimationController _iconScaleController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _iconOpacityAnimation;

  final double _swipeThreshold = 50;
  final List<bool> _granted = List<bool>.filled(2, false);
  final _permissions = [
    PermissionData(
      icon: Icons.notifications,
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Send you important updates and alerts',
    ),
    PermissionData(
      icon: Icons.mic,
      permission: Permission.microphone,
      title: 'Microphone',
      description: 'Access microphone to record audio',
    ),
  ];

  int _index = 0;

  // ignore: unused_field
  String _status = '';
  double _startX = 0;
  bool _isLoading = false;

  PermissionData get _current => _permissions[_index];

  String get _title => _current.title;

  bool get _isGranted => _granted[_index];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _iconRotationController.dispose();
    _iconScaleController.dispose();
    super.dispose();
  }

  void _initialize() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconRotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _iconScaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconScaleController, curve: Curves.elasticOut),
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _iconRotationController, curve: Curves.easeInOut),
    );

    _iconOpacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeIn),
    );

    _animateCurrent();
  }

  void _animateCurrent() {
    if (_index < _permissions.length) {
      _iconOpacityAnimation =
          Tween<double>(begin: _iconOpacityAnimation.value, end: 1.0).animate(
            CurvedAnimation(
              parent: _headerAnimationController,
              curve: Curves.easeIn,
            ),
          );

      // start animations
      _headerAnimationController.forward();
      _iconScaleController.forward();
      _iconRotationController.forward().then((_) {
        _iconRotationController.reset();
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final currentX = details.globalPosition.dx;
    final delta = _startX - currentX;

    if (delta.abs() > _swipeThreshold) {
      if (delta > 0 && _index < _permissions.length - 1 && _isGranted) {
        // Swiped left
        setState(() {
          _index++;
          _startX = currentX;
        });
      } else if (delta < 0 && _index > 0) {
        // Swiped right
        setState(() {
          _index--;
          _startX = currentX;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragStart: (details) => setState(() {
                      _startX = details.globalPosition.dx;
                    }),
                    onHorizontalDragEnd: (_) => setState(() => _startX = 0),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Icon
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _iconScaleAnimation,
                              _iconRotationAnimation,
                              _iconOpacityAnimation,
                            ]),
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _iconScaleAnimation.value,
                                child: Transform.rotate(
                                  angle: _iconRotationAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Icon(
                                      _current.icon,
                                      size: 64,
                                      color: colors.secondaryForeground,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Animated Title
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _title,
                              key: ValueKey(_index),
                              style: typography.xl2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Animated Description
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              _current.description,
                              key: ValueKey('desc_$_index'),
                              textAlign: TextAlign.center,
                              style: typography.base.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Progress Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_permissions.length, (
                              index,
                            ) {
                              return AnimatedContainer(
                                height: 8,
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: index == _index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: index == _index
                                      ? colors.primary
                                      : colors.muted,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    if (index < _index || _isGranted) {
                                      setState(() => _index = index);
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  spacing: 12,
                  children: [
                    FButton(
                      onPress: _isLoading
                          ? null
                          : (_isGranted ? _next : _request),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isGranted && _index < _permissions.length - 1
                                  ? 'Next'
                                  : 'Allow',
                            ),
                    ),
                    if (!_isGranted)
                      TextButton(
                        onPressed: _isLoading ? null : _skip,
                        child: Text(
                          'Skip for now',
                          style: typography.base.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// request current permission
  Future<void> _request() async {
    try {
      setState(() {
        _isLoading = false;
        _status = 'Requesting ${_current.title.toLowerCase()}...';
      });

      String message = '';
      final permission = await _current.permission.request();

      if (permission.isGranted) {
        message = '$_title access granted!';
      } else if (permission.isPermanentlyDenied) {
        message = '$_title permanently denied. Please enable in settings.';
        await _showDialog();
      } else {
        message = '$_title access denied.';
        _showToast(message: Text(message), icon: Icon(_current.icon));
      }

      setState(() {
        _status = message;
        _granted[_index] = permission.isGranted;
      });

      // wait a moment to show the result
      if (permission.isGranted) {
        await Future.delayed(const Duration(seconds: 1), _next);
      }
    } catch (e) {
      setState(() => _status = 'Error requesting permission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// skip current permission
  void _skip() {
    setState(() {
      _status = '$_title skipped. You can enable it later in settings.';
    });

    // wait a moment then next
    Future.delayed(const Duration(seconds: 1), () {
      if (_index < _permissions.length - 1) return _next();
      storage.write(key: _key, value: 'true');
      _navigate();
    });
  }

  /// move to next permission
  void _next() {
    if (_index < _permissions.length - 1) {
      setState(() {
        _index++;
        _status = '';
      });

      _iconScaleController.reset();
      _headerAnimationController.reset();
      _animateCurrent();

      return;
    }

    storage.write(key: _key, value: 'true'); // mark done
    _navigate();
  }

  /// navigate to next screens
  void _navigate() {
    final name = _userStore.isLogged ? '/main' : '/login';
    Navigator.of(context).pushNamedAndRemoveUntil(name, (_) => false);
  }

  void _showToast({required Text message, Icon? icon}) {
    showFToast(
      context: context,
      icon: icon,
      title: message,
      alignment: FToastAlignment.bottomCenter,
    );
  }

  /// show settings dialog
  Future<void> _showDialog() async {
    await showFDialog(
      context: context,
      builder: (context, style, animation) {
        return FDialog(
          style: style
              .copyWith(
                decoration: style.decoration.copyWith(
                  border: Border.all(color: context.theme.colors.border),
                ),
              )
              .call,
          animation: animation,
          direction: Axis.horizontal,
          title: Text('$_title Permission'),
          body: Text(
            '$_title permission was permanently denied. Would you like to open app settings to enable it manually?',
          ),
          actions: [
            FButton(
              style: FButtonStyle.outline(),
              mainAxisSize: MainAxisSize.min,
              onPress: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FButton(
              mainAxisSize: MainAxisSize.min,
              onPress: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    // after dismiss continue next
    // _next();
  }
}

class PermissionData {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;

  PermissionData({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
  });
}
