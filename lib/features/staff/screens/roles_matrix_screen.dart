import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/user_management_model.dart';
import 'package:poslaravelmobile/features/staff/providers/staff_provider.dart';

class RolesMatrixScreen extends StatefulWidget {
  const RolesMatrixScreen({super.key});

  @override
  State<RolesMatrixScreen> createState() => _RolesMatrixScreenState();
}

class _RolesMatrixScreenState extends State<RolesMatrixScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().fetchRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final staffProv = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hak Akses & Peran (Roles)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Matriks & konfigurasi izin per modul',
              style: TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => staffProv.fetchRoles(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(LucideIcons.shield, color: Colors.white, size: 18),
        label: const Text(
          'Tambah Peran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
        ),
        onPressed: () => _openRoleFormModal(context, null),
      ),
      body: staffProv.isLoadingRoles
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => staffProv.fetchRoles(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
                children: [
                  // Sleek Metric Summary Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          '${staffProv.roles.length}',
                          'Total Peran',
                          LucideIcons.shield,
                          const Color(0xFFF97316),
                        ),
                        Container(width: 1, height: 32, color: Colors.white12),
                        _buildSummaryItem(
                          '${staffProv.totalPermissionsCount}',
                          'Izin Menu',
                          LucideIcons.key,
                          const Color(0xFF38BDF8),
                        ),
                        Container(width: 1, height: 32, color: Colors.white12),
                        _buildSummaryItem(
                          '${staffProv.roles.fold<int>(0, (sum, r) => sum + r.usersCount)}',
                          'Staf Terdaftar',
                          LucideIcons.users,
                          const Color(0xFF4ADE80),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Peran & Hak Akses',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${staffProv.permissionModules.length} Modul Sistem',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Roles List
                  if (staffProv.roles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(LucideIcons.shieldAlert, size: 32, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            const Text(
                              'Belum ada peran termuat',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            if (staffProv.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                staffProv.errorMessage!,
                                style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => staffProv.fetchRoles(),
                              icon: const Icon(LucideIcons.refreshCw, size: 14),
                              label: const Text('Muat Ulang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...staffProv.roles.map((role) => _buildRoleCard(context, role, staffProv)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, RoleModel role, StaffProvider prov) {
    final isSuper = role.isSuperAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuper ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
          width: isSuper ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSuper ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSuper ? LucideIcons.shieldCheck : LucideIcons.shield,
                  color: isSuper ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.displayName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${role.usersCount} Staf aktif menggunakan peran ini',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isSuper ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSuper ? 'Full Access' : '${role.permissions.length} Izin',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSuper ? const Color(0xFFD97706) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Key: ${role.name}',
                style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => _openRoleFormModal(context, role),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSuper ? LucideIcons.eye : LucideIcons.sliders,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSuper ? 'Lihat Matriks' : 'Atur Izin',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isSuper && role.usersCount == 0) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 14, color: Color(0xFFEF4444)),
                      tooltip: 'Hapus Peran',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDeleteRole(context, role),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRole(BuildContext context, RoleModel role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Peran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus peran "${role.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              Navigator.pop(ctx);
              final prov = context.read<StaffProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final success = await prov.deleteRole(role.id);
              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Peran berhasil dihapus.')),
                  );
                } else {
                  final err = prov.errorMessage ?? 'Gagal menghapus peran.';
                  messenger.showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _openRoleFormModal(BuildContext context, RoleModel? role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RolePermissionsSheet(role: role),
    );
  }
}

class _RolePermissionsSheet extends StatefulWidget {
  final RoleModel? role;
  const _RolePermissionsSheet({this.role});

  @override
  State<_RolePermissionsSheet> createState() => _RolePermissionsSheetState();
}

class _RolePermissionsSheetState extends State<_RolePermissionsSheet> {
  late TextEditingController _nameCtrl;
  final Set<String> _selectedPermissions = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.role?.name ?? '');
    if (widget.role != null) {
      _selectedPermissions.addAll(widget.role!.permissions);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.role != null;
    final isSuper = widget.role?.isSuperAdmin ?? false;
    final staffProv = context.watch<StaffProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 18, left: 18, right: 18, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSuper ? LucideIcons.shieldCheck : LucideIcons.shield,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSuper
                            ? 'Izin Super Administrator'
                            : isEdit
                                ? 'Hak Akses: ${widget.role!.displayName}'
                                : 'Tambah Peran & Hak Akses',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
          const SizedBox(height: 12),

          if (!isEdit) ...[
            const Text('Nama Peran / Role *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 5),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Contoh: supervisor_outlet',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (isSuper)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 15, color: Color(0xFFEA580C)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peran Super Administrator memiliki hak akses penuh ke seluruh 11 modul sistem.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Permissions Matrix Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PILIH IZIN MENU (${_selectedPermissions.length} AKTIF)',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              if (!isSuper)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedPermissions.length >= staffProv.totalPermissionsCount) {
                        _selectedPermissions.clear();
                      } else {
                        for (final m in staffProv.permissionModules) {
                          _selectedPermissions.addAll(m.permissions.keys);
                        }
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      _selectedPermissions.length >= staffProv.totalPermissionsCount ? 'Batal Semua' : 'Pilih Semua',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Modules & Checkboxes List
          Expanded(
            child: ListView.separated(
              itemCount: staffProv.permissionModules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final module = staffProv.permissionModules[index];
                return _buildModuleAccordion(module, isSuper);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Submit Button
          if (!isSuper)
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
                onPressed: _isSaving ? null : _submitRole,
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Simpan Perubahan Hak Akses' : 'Buat Peran Sekarang', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleAccordion(PermissionModuleModel module, bool isSuper) {
    final activeCount = module.permissions.keys.where((k) => _selectedPermissions.contains(k)).length;
    final isAllChecked = activeCount == module.permissions.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  module.name,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAllChecked ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$activeCount/${module.permissions.length}',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isAllChecked ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          children: module.permissions.entries.map((perm) {
            final isChecked = isSuper || _selectedPermissions.contains(perm.key);
            return CheckboxListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              value: isChecked,
              activeColor: AppColors.primary,
              onChanged: isSuper
                  ? null
                  : (bool? val) {
                      setState(() {
                        if (val == true) {
                          _selectedPermissions.add(perm.key);
                        } else {
                          _selectedPermissions.remove(perm.key);
                        }
                      });
                    },
              title: Text(perm.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              subtitle: Text(perm.key, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _submitRole() async {
    final isEdit = widget.role != null;
    final name = isEdit ? widget.role!.name : _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama peran wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prov = context.read<StaffProvider>();
    final messenger = ScaffoldMessenger.of(context);
    bool success = false;

    if (isEdit) {
      success = await prov.updateRole(widget.role!.id, name, _selectedPermissions.toList());
    } else {
      success = await prov.storeRole(name, _selectedPermissions.toList());
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text(isEdit ? 'Hak akses berhasil diperbarui.' : 'Peran baru berhasil dibuat.')),
        );
      } else {
        final err = prov.errorMessage ?? 'Gagal menyimpan peran.';
        messenger.showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }
}
