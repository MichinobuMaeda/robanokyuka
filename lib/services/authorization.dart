import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'helpers.dart';
import 'authentication.dart';
import '../models/service.dart';
import '../views/auth/email_link_panel.dart';
import '../views/auth/email_password_panel.dart';
import '../views/auth/reset_password_panel.dart';
import '../views/user/record_panel.dart';
import '../views/user/summary_panel.dart';
import '../views/user/calendar_panel.dart';
import '../views/user/edit_profile_panel.dart';
import '../views/auth/sign_out_panel.dart';
import '../views/auth/password_reauthenticate_panel.dart';
import '../views/auth/change_email_panel.dart';
import '../views/auth/google_auth_panel.dart';
import '../views/auth/delete_user_panel.dart';
import '../views/admin/users_panel.dart';
import '../views/admin/holidays_panel.dart';
import '../widgets/markdown_panel.dart';

enum Privilege { loading, guest, admin, user }

enum PageItem {
  guest(
    icon: Symbols.login,
    label: '利用開始',
    privileges: [Privilege.guest],
    contents: [
      MarkdownPanel(asset: assetGuestMd),
      EmailLinkPanel(),
      EmailPasswordPanel(),
      ResetPasswordPanel(),
      GoogleAuthPanel(),
    ],
  ),
  home(
    icon: Symbols.calendar_month,
    label: '記録',
    privileges: [Privilege.user, Privilege.admin],
    contents: [RecordPanel(), SummaryPanel(), CalendarPanel()],
  ),
  settings(
    icon: Symbols.account_circle,
    label: '設定',
    privileges: [Privilege.user, Privilege.admin],
    contents: [
      EditProfilePanel(),
      ResetPasswordPanel(),
      SignOutPanel(),
      MarkdownPanel(asset: assetReauthenticateMd),
      EmailLinkPanel(),
      PasswordReauthenticatePanel(),
      GoogleAuthPanel(reauthentication: true),
      ChangeEmailPanel(),
      DeleteUserPanel(),
    ],
  ),
  admin(
    icon: Symbols.admin_panel_settings,
    label: '管理',
    privileges: [Privilege.admin],
    contents: [UsersPanel(), HolidaysPanel()],
  ),
  info(
    icon: Symbols.info,
    label: '情報',
    privileges: Privilege.values,
    contents: [MarkdownPanel(asset: assetInfoMd)],
  );

  const PageItem({
    required this.icon,
    required this.label,
    required this.privileges,
    required this.contents,
  });

  final IconData icon;
  final String label;
  final List<Privilege> privileges;
  final List<Widget> contents;
}

final privilegeProvider = Provider<Privilege>((ref) {
  final authUser = ref.watch(authUserProvider);
  final service = ref.watch(serviceProvider);
  final admins = ref.watch(adminsProvider);

  return authUser.isLoading || service.isLoading
      ? Privilege.loading
      : ((authUser.asData?.value == null)
            ? Privilege.guest
            : (admins.contains(authUser.asData!.value!.uid)
                  ? Privilege.admin
                  : Privilege.user));
});

final pagesProvider = Provider<List<PageItem>>((ref) {
  final privilege = ref.watch(privilegeProvider);
  return PageItem.values
      .where((item) => item.privileges.contains(privilege))
      .toList();
});
