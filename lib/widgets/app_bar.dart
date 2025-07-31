import 'package:flipcard/helpers/ad_mob.dart';
import 'package:flipcard/helpers/logger.dart';
import 'package:flipcard/services/user_service.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flipcard/widgets/badge.dart';
import 'package:provider/provider.dart';

class AppBarPrimary extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const AppBarPrimary({super.key, this.title, this.actions, this.bottom});

  Future<void> _earnGems(BuildContext context, UserStore userStore) async {
    try {
      if (!AdMob.isReady(AdType.rewarded)) return;
      final showAd = await showFDialog(
        context: context,
        builder: (context, style, animation) => FDialog(
          animation: animation,
          direction: Axis.horizontal,
          style: style
              .copyWith(
                decoration: style.decoration.copyWith(
                  border: Border.all(color: context.theme.colors.border),
                ),
              )
              .call,
          title: const Text('Earn Embergems'),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Watch a short video to earn embergems.'),
              SizedBox(height: 16),
              Row(
                children: [
                  Image.asset(
                    'assets/images/embergems.png',
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '+3 Embergems',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            FButton(
              mainAxisSize: MainAxisSize.min,
              style: FButtonStyle.outline(),
              onPress: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FButton(
              mainAxisSize: MainAxisSize.min,
              onPress: () => Navigator.pop(context, true),
              suffix: Icon(FIcons.monitorPlay, size: 16),
              child: const Text('Watch Ad'),
            ),
          ],
        ),
      );

      if (showAd) {
        await AdMob.show(
          AdType.rewarded,
          onEarned: (ad, reward) async {
            Logger.log('earn reward: ${reward.amount}', name: 'EarnGems');
            final user = userStore.user?.copyWith(
              embergems: await UserService.addGems(reward.amount.toInt()),
            );
            userStore.updateUser(user);
            AdMob.reload(AdType.rewarded);
          },
        );
      }
    } catch (e) {
      Logger.log(e.toString(), name: 'EarnGems');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final userStore = Provider.of<UserStore>(context);

    return AppBar(
      title: title,
      bottom: bottom,
      surfaceTintColor: colors.secondary,
      backgroundColor: colors.secondary,
      actions: [
        ...?actions,
        GestureDetector(
          onTap: () => _earnGems(context, userStore),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IconButton(
                iconSize: 12,
                icon: Icon(FIcons.plus),
                onPressed: () => _earnGems(context, userStore),
                tooltip: "Earn embergems",
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  shape: CircleBorder(),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
              ),
              SizedBox(width: 2),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 100),
                child: TBadge(
                  maxLines: 1,
                  label: '${userStore.user?.embergems ?? 0}',
                  style: theme.typography.sm,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                ),
              ),
              SizedBox(width: 4),
              Image.asset(
                'assets/images/embergems.png',
                width: 18,
                height: 18,
                frameBuilder: (ctx, child, frame, sync) {
                  if (frame == null) {
                    return Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.15),
                      ),
                      child: Center(child: Icon(FIcons.loader, size: 14)),
                    );
                  }
                  return child;
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppBarSecondary extends StatefulWidget implements PreferredSizeWidget {
  final String hint;
  final List<Widget>? actions;
  final Function(String value)? onSearch;

  const AppBarSecondary({
    super.key,
    this.hint = 'Search...',
    this.onSearch,
    this.actions,
  });

  @override
  State<AppBarSecondary> createState() => _AppBarSecondaryState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarSecondaryState extends State<AppBarSecondary> {
  late final FocusNode _focusNode;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (_searchController.text.isEmpty || _searchController.text.length > 2) {
      widget.onSearch?.call(_searchController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return AppBar(
      primary: false,
      automaticallyImplyLeading: false,
      surfaceTintColor: colors.secondary,
      backgroundColor: Colors.transparent,
      flexibleSpace: Material(
        elevation: 0, // increase to show the shadow
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        color: colors.secondary,
        child: Container(),
      ),
      title: SizedBox(
        height: 40,
        child: Focus(
          onFocusChange: (value) {
            if (!value) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: TextField(
            focusNode: _focusNode,
            controller: _searchController,
            onTapUpOutside: (event) => _focusNode.unfocus(),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.background,
              hintText: widget.hint,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              prefixIcon: Icon(Icons.search, color: colors.mutedForeground),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _focusNode.unfocus();
                      },
                      child: Icon(
                        Icons.clear,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                    ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border, width: 1.0),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      actions: widget.actions,
    );
  }
}

class AppBarSliver extends StatelessWidget {
  const AppBarSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'SliverAppBar',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              background: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://images.joseartgallery.com/100736/what-kind-of-art-is-popular-right-now.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            floating: false,
            pinned: true,
            snap: false,
            elevation: 10.0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Search action
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // More options
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              // height: 200,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      'Item $index',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
