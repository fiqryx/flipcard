import 'package:flipcard/constants/config.dart';
import 'package:flipcard/constants/enums.dart';
import 'package:flipcard/constants/storage.dart';
import 'package:flipcard/widgets/app_bar.dart';
import 'package:flipcard/widgets/button_group.dart';
import 'package:flutter/material.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserStore _userStore;
  final _layoutKey = 'home_layout';

  bool _isLoading = false;
  ViewMode _viewMode = ViewMode.list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final layout = await storage.read(key: _layoutKey);
      setState(() {
        _viewMode = layout == 'grid' ? ViewMode.grid : ViewMode.list;
      });

      await _userStore.getData();
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          icon: Icon(FIcons.circleX),
          title: Text(e.toString().replaceAll('Exception: ', '')),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleLayout() async {
    final isList = _viewMode == ViewMode.list;
    await storage.write(key: _layoutKey, value: isList ? 'grid' : 'list');
    setState(() => _viewMode = isList ? ViewMode.grid : ViewMode.list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarPrimary(
        title: Row(
          spacing: 8,
          children: [
            SvgPicture.asset('assets/svg/icon_logo.svg'),
            Text(
              appName,
              style: context.theme.typography.base.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Scaffold(
        appBar: AppBarSecondary(
          hint: 'Search...',
          actions: [
            ButtonGroup(
              children: [
                ButtonGroupItem(
                  width: 30,
                  height: 30,
                  icon: FIcons.layoutList,
                  isActive: _viewMode == ViewMode.list,
                  onPressed: _viewMode == ViewMode.list ? null : _toggleLayout,
                ),
                ButtonGroupItem(
                  width: 30,
                  height: 30,
                  icon: FIcons.layoutGrid,
                  isActive: _viewMode == ViewMode.grid,
                  onPressed: _viewMode == ViewMode.grid ? null : _toggleLayout,
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator.adaptive(
                onRefresh: _loadData,
                child: Placeholder(),
              ),
      ),
    );
  }
}
