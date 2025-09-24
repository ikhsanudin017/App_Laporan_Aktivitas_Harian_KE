class UserOption {
  const UserOption({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;
}

const List<UserOption> userOptions = [
  UserOption(
      id: 1,
      name: 'Bapak Arwan',
      email: 'arwan@ksuke.com',
      role: 'BAPAK_ARWAN'),
  UserOption(
      id: 2,
      name: 'Bpk Winarno',
      email: 'winarno@ksuke.com',
      role: 'BPK_WINARNO'),
  UserOption(
      id: 3,
      name: 'Bapak Giyarto',
      email: 'giyarto@ksuke.com',
      role: 'BAPAK_GIYARTO'),
  UserOption(
      id: 4, name: 'Bapak Toha', email: 'toha@ksuke.com', role: 'BAPAK_TOHA'),
  UserOption(
      id: 5,
      name: 'Bapak Sayudi',
      email: 'sayudi@ksuke.com',
      role: 'BAPAK_SAYUDI'),
  UserOption(
      id: 6, name: 'Ustadz Yuli', email: 'yuli@ksuke.com', role: 'USTADZ_YULI'),
  UserOption(
      id: 7,
      name: 'Bapak Prasetyo Dani',
      email: 'prasetyo@ksuke.com',
      role: 'BAPAK_PRASETYO'),
  UserOption(
      id: 8,
      name: 'Bapak Diah Supriyanto',
      email: 'diah@ksuke.com',
      role: 'BAPAK_DIAH'),
];
