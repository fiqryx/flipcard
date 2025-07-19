import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flipcard/widgets/badge.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flipcard/screens/profile_screen.dart';

class AppBarPrimary extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool showUser;
  final PreferredSizeWidget? bottom;

  const AppBarPrimary({
    super.key,
    this.title,
    this.actions,
    this.showUser = false,
    this.bottom,
  });

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
        if (showUser)
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Row(
              spacing: 4,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  spacing: 2,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userStore.user?.name ?? 'Guest',
                      style: theme.typography.sm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TBadge(label: 'subscribtion'),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.all(4),
                  tooltip: userStore.user?.name,
                  style: IconButton.styleFrom(shape: CircleBorder()),
                  icon: FAvatar(
                    size: 36,
                    style: (style) => style.copyWith(
                      // ignore: deprecated_member_use
                      backgroundColor: colors.mutedForeground.withOpacity(0.2),
                      foregroundColor: colors.primaryForeground,
                    ),
                    image: NetworkImage(userStore.user?.imageUrl ?? ''),
                    fallback: Icon(Icons.person),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
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
