import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/models/service.dart';

enum Privilege { loading, guest, admin, user }

enum PageItem {
  guest(icon: Symbols.login, label: '利用開始', privileges: [Privilege.guest]),
  home(
    icon: Symbols.calendar_month,
    label: '記録',
    privileges: [Privilege.user, Privilege.admin],
  ),
  settings(
    icon: Symbols.account_circle,
    label: '設定',
    privileges: [Privilege.user, Privilege.admin],
  ),
  admin(
    icon: Symbols.admin_panel_settings,
    label: '管理',
    privileges: [Privilege.admin],
  ),
  info(icon: Symbols.info, label: '情報', privileges: Privilege.values);

  const PageItem({
    required this.icon,
    required this.label,
    required this.privileges,
  });

  final IconData icon;
  final String label;
  final List<Privilege> privileges;
}

final privilegeProvider = Provider<Privilege>((ref) {
  final authUser = ref.watch(authUserProvider);
  final service = ref.watch(serviceProvider);
  final admins = ref.watch(confProvider.select((conf) => conf?.admins ?? []));

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
