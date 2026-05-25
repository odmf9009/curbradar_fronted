import 'package:flutter/material.dart';
import '../../../core/models/report_model.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/objects_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/config/routes.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Panel de Administrador',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add, color: Colors.blue),
              tooltip: 'Cambiar de cuenta',
              onPressed: () =>
                  _showSwitchAccountDialog(context, authService),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Limpiar todo',
              onPressed: () => _showDeleteAllDialog(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFFFF8A00),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFF8A00),
            tabs: [
              Tab(
                  text: 'Reportes',
                  icon: Icon(Icons.report_problem_outlined)),
              Tab(
                  text: 'Usuarios',
                  icon: Icon(Icons.people_outline)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReportsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }

  void _showSwitchAccountDialog(
      BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Cambiar de cuenta'),
        content: const Text(
            'Se cerrará la sesión actual y se te pedirá seleccionar una cuenta de Google diferente para probar la app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Limpiar Base de Datos',
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
            '¿Estás seguro de que quieres eliminar TODOS los objetos de la aplicación? Esta acción borrará el mapa por completo y es irreversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService()
                    .delete('${ApiConfig.admin}/objects/all');
              } catch (_) {}
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Base de datos limpiada con éxito')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Borrar Todo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- Reports Tab ---
class _ReportsTab extends StatefulWidget {
  const _ReportsTab();
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final ApiService _api = ApiService();
  final ObjectsService _objectsService = ObjectsService();
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await _api.get('${ApiConfig.admin}/reports');
      final List<dynamic> data = response.data['reports'] ?? [];
      if (mounted) {
        setState(() {
          _reports = data.map((json) => ReportModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8A00)));
    }
    if (_reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('¡Todo limpio!',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('No hay reportes que revisar.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: const Color(0xFFFF8A00),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          return _ReportCard(
            report: _reports[index],
            api: _api,
            objectsService: _objectsService,
            onDismissed: () {
              setState(() => _reports.removeAt(index));
            },
          );
        },
      ),
    );
  }
}

// --- Users Tab ---
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final ApiService _api = ApiService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('${ApiConfig.admin}/users');
      final List<dynamic> data = response.data['users'] ?? [];
      if (mounted) {
        setState(() {
          _users = data.map((json) => UserModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8A00)));
    }
    if (_users.isEmpty) {
      return const Center(
          child: Text('No hay usuarios registrados'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.withOpacity(0.05),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Total de usuarios registrados: ${_users.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            color: const Color(0xFFFF8A00),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user.profileImageUrl.isNotEmpty
                        ? NetworkImage(user.profileImageUrl)
                        : null,
                    child: user.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          user.username.isNotEmpty
                              ? '@${user.username}'
                              : 'Sin alias',
                          style: const TextStyle(
                              color: Color(0xFFFF8A00), fontSize: 13)),
                      Text(user.email,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Nivel ${user.level}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('${user.points} pts',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// --- Report Card ---
class _ReportCard extends StatefulWidget {
  final ReportModel report;
  final ApiService api;
  final ObjectsService objectsService;
  final VoidCallback onDismissed;

  const _ReportCard({
    required this.report,
    required this.api,
    required this.objectsService,
    required this.onDismissed,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  CurbObject? _object;
  bool _objectLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadObject();
  }

  Future<void> _loadObject() async {
    try {
      final obj = await widget.objectsService
          .getObjectById(widget.report.objectId);
      if (mounted) {
        setState(() {
          _object = obj;
          _objectLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _objectLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeleted = _objectLoaded && _object == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Report Header (Reason)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.report_problem,
                    color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Motivo: ${widget.report.reason}',
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                Text(
                  _formatDate(widget.report.createdAt),
                  style: TextStyle(
                      color: Colors.red[300], fontSize: 11),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _object != null &&
                            _object!.imageUrls.isNotEmpty
                        ? Image.network(_object!.imageUrls[0],
                            fit: BoxFit.cover)
                        : Icon(Icons.image_not_supported,
                            color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeleted
                            ? 'Objeto ya eliminado'
                            : (_object?.title ?? 'Cargando...'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDeleted
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reportado por ID: ${widget.report.reportedByUserId.substring(0, 8)}...',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                      if (!isDeleted && _object != null)
                        Text(
                          _object!.address,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (!isDeleted && _object != null)
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined,
                        color: Colors.blue),
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.objectDetail,
                        arguments: _object),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    label: const Text('Ignorar',
                        style: TextStyle(color: Colors.green)),
                    onPressed: () => _handleDismiss(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    label: const Text('Borrar Post',
                        style: TextStyle(color: Colors.red)),
                    onPressed:
                        isDeleted ? null : () => _handleDeletePost(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDismiss(BuildContext context) async {
    try {
      await widget.api.delete(
          '${ApiConfig.admin}/reports/${widget.report.id}');
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte ignorado')));
      widget.onDismissed();
    }
  }

  void _handleDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar publicación?'),
        content: const Text(
            'Esta acción eliminará el objeto del mapa y cerrará este reporte.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                await widget.api.delete(
                    '${ApiConfig.admin}/objects/${widget.report.objectId}');
              } catch (_) {}
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Objeto eliminado')));
                widget.onDismissed();
              }
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
