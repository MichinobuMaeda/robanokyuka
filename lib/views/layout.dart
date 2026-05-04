import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:web/web.dart' as web;

import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/config/theme.dart';
import 'package:yukyuchecker/config/version.dart';
import 'package:yukyuchecker/models/service.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/services/authorization.dart';
import 'package:yukyuchecker/services/helpers.dart';

enum MediaSize { narrow, middle, wide }

class Layout extends HookConsumerWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privilege = ref.watch(privilegeProvider);
    final pages = ref.watch(pagesProvider);
    final uiVersion = ref.watch(confProvider.select((conf) => conf?.uiVersion));
    final selectedIndex = useState(0);
    final selectedPage = useState(pages.first);

    if (ref.watch(serviceProvider).hasError) {
      debugPrint('Error loading service: ${ref.watch(serviceProvider).error}');
      signOut(auth());
    }

    ref.listen<String?>(snackBarMessageProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      if (next != null && next.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(next)));
      }
    });

    void onDestinationSelected(int index) {
      selectedIndex.value = index;
      selectedPage.value = pages[index];
    }

    useEffect(() {
      selectedIndex.value = 0;
      selectedPage.value = pages.first;
      return null;
    }, [privilege]);

    useEffect(() {
      if (selectedIndex.value >= pages.length) {
        selectedIndex.value = pages.length - 1;
      }
      return null;
    }, [pages.length]);

    final mediaSize = MediaQuery.sizeOf(context);
    MediaSize media() => mediaSize.width < mediaSize.height
        ? MediaSize.narrow
        : (mediaSize.width < (navDrawerWidth + contentMaxWidth)
              ? MediaSize.middle
              : MediaSize.wide);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Row(
          children: [
            if (media() == MediaSize.middle)
              _NavRail(
                pages: pages,
                selectedIndex: selectedIndex.value,
                onDestinationSelected: onDestinationSelected,
              ),
            if (media() == MediaSize.wide)
              _NavDrawer(
                pages: pages,
                selectedIndex: selectedIndex.value,
                onDestinationSelected: onDestinationSelected,
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: CustomScrollView(
                    slivers: [
                      if (media() != MediaSize.wide) const _Header(),
                      if (uiVersion != null && uiVersion != packageVersion)
                        const _UpdateAvailable(),
                      ...selectedPage.value.contents,
                      const _Footer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: media() == MediaSize.narrow
          ? _NavBar(
              pages: pages,
              selectedIndex: selectedIndex.value,
              onDestinationSelected: onDestinationSelected,
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Image.asset(assetAppLogo, height: 48.0),
      ),
    );
  }
}

class _UpdateAvailable extends StatelessWidget {
  const _UpdateAvailable();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: FilledButton(
          onPressed: () => web.window.location.reload(),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4.0,
            children: [
              Icon(
                Symbols.sync,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              Text(
                'アプリをアップデートしてください',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('yukyuchecker $packageVersion'),
      ),
    );
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer({
    required this.pages,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<PageItem> pages;
  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: navDrawerWidth,
      child: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        header: Padding(
          padding: EdgeInsets.all(8.0),
          child: Image.asset(assetAppLogo),
        ),
        children: pages
            .map(
              (item) => NavigationDrawerDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.pages,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<PageItem> pages;
  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      labelType: NavigationRailLabelType.all,
      destinations: pages
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              label: Text(item.label),
            ),
          )
          .toList(),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.pages,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<PageItem> pages;
  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: pages
          .map(
            (item) =>
                NavigationDestination(icon: Icon(item.icon), label: item.label),
          )
          .toList(),

      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}
