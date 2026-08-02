import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/config/version.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/platform/platforms.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/services/authorization.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/views/auth/change_email_panel.dart';
import 'package:robanokyuka/views/auth/delete_user_panel.dart';
import 'package:robanokyuka/views/auth/email_link_panel.dart';
import 'package:robanokyuka/views/auth/email_password_panel.dart';
import 'package:robanokyuka/views/auth/password_reauthenticate_panel.dart';
import 'package:robanokyuka/views/auth/reset_password_panel.dart';
import 'package:robanokyuka/views/auth/federated_auth_panel.dart';
import 'package:robanokyuka/views/auth/register_panel.dart';
import 'package:robanokyuka/views/auth/sign_out_panel.dart';
import 'package:robanokyuka/views/admin/holidays_panel.dart';
import 'package:robanokyuka/views/admin/gengos_panel.dart';
import 'package:robanokyuka/views/admin/ui_versions.dart';
import 'package:robanokyuka/views/admin/users_panel.dart';
import 'package:robanokyuka/views/user/calendar_panel.dart';
import 'package:robanokyuka/views/user/edit_day_panel.dart';
import 'package:robanokyuka/views/user/edit_profile_panel.dart';
import 'package:robanokyuka/views/user/edit_record_panel.dart';
import 'package:robanokyuka/views/user/record_panel.dart';
import 'package:robanokyuka/views/user/summary_panel.dart';
import 'package:robanokyuka/views/update_available_panel.dart';
import 'package:robanokyuka/widgets/markdown_panel.dart';

enum MediaSize { narrow, middle, wide }

List<Widget> getContents(
  PageItem pageItem,
  bool isRecordEditing,
  bool isDateEditing,
) => switch (pageItem) {
  PageItem.guest => [
    MarkdownPanel(asset: assetGuestMd, showDivider: false),
    FederatedAuthPanel(),
    if (getAppEnvironment() == AppEnvironment.web) EmailLinkPanel(),
    EmailPasswordPanel(),
    ResetPasswordPanel(),
  ],
  PageItem.register => [
    MarkdownPanel(asset: assetGuestMd, showDivider: false),
    FederatedAuthPanel(),
    if (getAppEnvironment() == AppEnvironment.web) EmailLinkPanel(),
    RegisterPanel(),
  ],
  PageItem.home =>
    isRecordEditing
        ? [EditRecordPanel()]
        : isDateEditing
        ? [EditDayPanel()]
        : [RecordPanel(), SummaryPanel(), CalendarPanel()],
  PageItem.settings => [
    EditProfilePanel(),
    ResetPasswordPanel(),
    SignOutPanel(),
    MarkdownPanel(asset: assetReauthenticateMd),
    if (getAppEnvironment() == AppEnvironment.web) EmailLinkPanel(),
    PasswordReauthenticatePanel(),
    FederatedAuthPanel(reauthentication: true),
    ChangeEmailPanel(),
    DeleteUserPanel(),
  ],
  PageItem.admin => [
    UiVersionsPanel(),
    UsersPanel(),
    HolidaysPanel(),
    GengosPanel(),
  ],
  PageItem.info => [MarkdownPanel(asset: assetInfoMd)],
};

class Layout extends HookConsumerWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privilege = ref.watch(privilegeProvider);
    final pages = ref.watch(pagesProvider);

    if (privilege == Privilege.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedIndex = useState(0);
    final selectedPage = useState(pages.first);

    if (ref.watch(serviceProvider).hasError) {
      debugPrint('Error loading service: ${ref.watch(serviceProvider).error}');
      signOut(ref.read(authProvider));
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

    final isRecordEditing = ref.watch(editingRecordProvider) != null;
    final isDateEditing = ref.watch(editingDateProvider) != null;

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
                      const UpdateAvailablePanel(),
                      ...getContents(
                        selectedPage.value,
                        isRecordEditing,
                        isDateEditing,
                      ),
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
        child: SvgPicture.asset(assetAppLogo, height: 48.0),
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
        child: Text('robanokyuka $packageVersion'),
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
          padding: EdgeInsets.all(16.0),
          child: SvgPicture.asset(assetAppLogo),
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
