import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/widgets/app_sidebar_drawer.dart';
import 'package:poslaravelmobile/data/models/user_management_model.dart';
import 'package:poslaravelmobile/features/staff/providers/staff_provider.dart';
import 'package:poslaravelmobile/features/staff/screens/roles_matrix_screen.dart';

class StaffUsersScreen extends StatefulWidget {
  const StaffUsersScreen({super.key});

  @override
  State<StaffUsersScreen> createState() => _StaffUsersScreenState();
}

class _StaffUsersScreenState extends State<StaffUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().fetchAllData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffProv = context.watch<StaffProvider>();
    final activeUsersCount = staffProv.users.where((u) => u.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staf & Pengguna',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Manajemen akses & data staf kasir',
              style: TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Hak Akses & Peran',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 19),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RolesMatrixScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => staffProv.fetchAllData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        highlightElevation: 2,
        icon: const Icon(LucideIcons.userPlus, color: Colors.white, size: 18),
        label: const Text(
          'Tambah Staf',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
        ),
        onPressed: () => _openUserFormModal(context, null),
      ),
      body: Column(
        children: [
          // Filter & Mini Stats Compact Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                // Mini Stats Metric Bar (Clean & Compact)
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniHeaderStat(
                        label: 'Total Pengguna',
                        value: '${staffProv.users.length}',
                        icon: LucideIcons.users,
                        color: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniHeaderStat(
                        label: 'Staf Aktif',
                        value: '$activeUsersCount',
                        icon: LucideIcons.userCheck,
                        color: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniHeaderStat(
                        label: 'Total Peran',
                        value: '${staffProv.roles.length}',
                        icon: LucideIcons.shield,
                        color: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFFFBEB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Input with modern sleek styling
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => staffProv.setSearchQuery(val.trim()),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari staf berdasarkan nama, email, no HP...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 15, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                staffProv.setSearchQuery(null);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Role Filter Chips with scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCompactChip(staffProv, null, 'Semua Peran'),
                      ...staffProv.roles.map((r) => _buildCompactChip(staffProv, r.name, r.displayName)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Users List Content
          Expanded(
            child: staffProv.isLoadingUsers
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : staffProv.users.isEmpty
                    ? _buildEmptyState(staffProv)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => staffProv.fetchAllData(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 85),
                          itemCount: staffProv.users.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user = staffProv.users[index];
                            return _buildUserCard(context, user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHeaderStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color, height: 1.1),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(StaffProvider prov, String? roleKey, String label) {
    final isSelected = prov.selectedRoleFilter == roleKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => prov.setRoleFilter(roleKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, StaffUserModel user) {
    Color roleColor = const Color(0xFF64748B);
    Color roleBg = const Color(0xFFF1F5F9);
    IconData roleIcon = LucideIcons.user;

    switch (user.primaryRole.toLowerCase()) {
      case 'super_admin':
        roleColor = const Color(0xFFD97706);
        roleBg = const Color(0xFFFEF3C7);
        roleIcon = LucideIcons.shieldCheck;
        break;
      case 'owner':
        roleColor = const Color(0xFF7C3AED);
        roleBg = const Color(0xFFEDE9FE);
        roleIcon = LucideIcons.crown;
        break;
      case 'manager':
        roleColor = const Color(0xFF2563EB);
        roleBg = const Color(0xFFDBEAFE);
        roleIcon = LucideIcons.briefcase;
        break;
      case 'cashier':
        roleColor = const Color(0xFF059669);
        roleBg = const Color(0xFFD1FAE5);
        roleIcon = LucideIcons.shoppingBag;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sleek Initial Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: user.isActive
                    ? [const Color(0xFFEA580C), const Color(0xFFF59E0B)]
                    : [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Core Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        user.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: user.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 10, color: roleColor),
                          const SizedBox(width: 3.5),
                          Text(
                            user.roleDisplay,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.email,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        user.phone!,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action Menu
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 16, color: Color(0xFF94A3B8)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == 'edit') {
                _openUserFormModal(context, user);
              } else if (action == 'delete') {
                _confirmDeleteUser(context, user);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                height: 38,
                child: Row(
                  children: [
                    Icon(LucideIcons.edit3, size: 15, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Edit Staf', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                height: 38,
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 15, color: Color(0xFFDC2626)),
                    SizedBox(width: 8),
                    Text('Hapus Akun', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(StaffProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.users, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada data staf / pengguna',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tambahkan staf baru untuk memberikan hak akses kasir atau kelola toko.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openUserFormModal(context, null),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Tambah Staf Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, StaffUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 18),
            SizedBox(width: 8),
            Text('Hapus Staf', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "${user.name}"? Akses login staf ini akan dinonaktifkan permanen.',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final prov = context.read<StaffProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final success = await prov.deleteUser(user.id);
              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Staf berhasil dihapus.')),
                  );
                } else {
                  final err = prov.errorMessage ?? 'Gagal menghapus staf.';
                  messenger.showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openUserFormModal(BuildContext context, StaffUserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserFormSheet(user: user),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final StaffUserModel? user;
  const _UserFormSheet({this.user});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _passwordCtrl;
  String _selectedRole = 'cashier';
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _passwordCtrl = TextEditingController();
    _selectedRole = u?.primaryRole ?? 'cashier';
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final staffProv = context.watch<StaffProvider>();
    final availableRoles = staffProv.roles.isNotEmpty
        ? staffProv.roles.map((r) => r.name).toList()
        : ['super_admin', 'owner', 'manager', 'cashier'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isEdit ? LucideIcons.userCheck : LucideIcons.userPlus,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEdit ? 'Edit Data Staf' : 'Tambah Staf Baru',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 17),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Name
              const Text('Nama Lengkap *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 13),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                decoration: _inputDecoration('Contoh: Budi Santoso', LucideIcons.user),
              ),
              const SizedBox(height: 10),

              // Email & Phone in 2 compact fields
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alamat Email *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _emailCtrl,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Email valid wajib' : null,
                          decoration: _inputDecoration('nama@toko.com', LucideIcons.mail),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nomor WhatsApp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _phoneCtrl,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('08123456789', LucideIcons.phone),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Role Selection
              const Text('Peran Hak Akses (Role) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: availableRoles.contains(_selectedRole) ? _selectedRole : availableRoles.first,
                    items: availableRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Password
              Text(
                isEdit ? 'Ganti Kata Sandi (Opsional)' : 'Kata Sandi Masuk *',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 13),
                validator: (v) {
                  if (!isEdit && (v == null || v.length < 8)) {
                    return 'Kata sandi minimal 8 karakter';
                  }
                  if (isEdit && v != null && v.isNotEmpty && v.length < 8) {
                    return 'Kata sandi minimal 8 karakter';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: isEdit ? 'Kosongkan jika tidak diganti' : 'Minimal 8 karakter',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.lock, size: 15, color: Color(0xFF64748B)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 34),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 15, color: const Color(0xFF64748B)),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Active Status Toggle (Compact)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Akun Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        Text('Izinkan staf masuk & operasikan POS', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Simpan Perubahan Staf' : 'Tambah Staf Sekarang', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, size: 15, color: const Color(0xFF64748B)),
      prefixIconConstraints: const BoxConstraints(minWidth: 34),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final prov = context.read<StaffProvider>();
    final messenger = ScaffoldMessenger.of(context);
    bool success = false;

    if (widget.user != null) {
      success = await prov.updateUser(
        id: widget.user!.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
        role: _selectedRole,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        isActive: _isActive,
      );
    } else {
      success = await prov.storeUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _selectedRole,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        isActive: _isActive,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text(widget.user != null ? 'Data staf berhasil diperbarui.' : 'Staf baru berhasil ditambahkan.')),
        );
      } else {
        final err = prov.errorMessage ?? 'Terjadi kesalahan saat menyimpan data.';
        messenger.showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }
}
