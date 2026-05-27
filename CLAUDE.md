# 🧠 CLAUDE.md — curbradar_frontend

> **LEE ESTE ARCHIVO COMPLETO ANTES DE HACER CUALQUIER TAREA.**
> Cubre exclusivamente el frontend Flutter. Para contexto de negocio completo, lee también
> `curb_radar_backup/CLAUDE.md` (reglas de negocio, flujos de usuario, historia del proyecto).

---

## 1. ¿Qué es este proyecto?

`curbradar_frontend/` es el cliente Flutter de **CurbRadar** en su arquitectura híbrida.
Consume un backend Node.js propio (`curbradar_backend/`) en lugar de Firestore.

**Lo que hace este Flutter:**
- Login via Firebase Auth → obtiene ID Token → lo envía al backend
- Muestra objetos en Google Maps en tiempo real via **Socket.io**
- Sube imágenes enviándolas al **backend** (nunca directo a Firebase Storage)
- Recibe push notifications via **Firebase FCM**
- TODO el estado de negocio viene del backend REST — nada se calcula en el cliente

---

## 2. Qué Firebase usa este frontend (y qué NO usa)

```
Firebase Auth        ✅ DIRECTO desde Flutter → login Google/email, ID Token
Firebase FCM         ✅ DIRECTO desde Flutter → recepción de push notifications
─────────────────────────────────────────────────────────────────────────────
cloud_firestore      ❌ PROHIBIDO — reemplazado por REST + Socket.io
firebase_storage     ❌ PROHIBIDO — el backend sube las imágenes
google_generative_ai ❌ PROHIBIDO — Gemini corre en el backend
```

Si ves alguno de estos tres paquetes importado en cualquier archivo: **es un bug**.

---

## 3. Stack Completo

| Capa | Tecnología | Notas |
|------|-----------|-------|
| Framework | Flutter / Dart | Material Design 3 |
| Auth | `firebase_auth` + `google_sign_in` | Solo para login e ID Token |
| HTTP / REST | `dio` ^5.6.0 | Singleton con interceptor de token |
| Tiempo real | `socket_io_client` ^2.0.3+1 | Reemplaza Firestore Streams |
| Push (recepción) | `firebase_messaging` + `flutter_local_notifications` | Sin Firestore |
| Mapas | `google_maps_flutter` ^2.10.0 | Google Maps con markers |
| GPS | `geolocator` ^14.0.2 | Posición del usuario |
| Imágenes | `image_picker` ^1.1.2 → `UploadService` | Jamás directo a Storage |
| UI extras | `shimmer`, `confetti`, `share_plus` | Loading, celebración, compartir |
| Preferencias | `shared_preferences` ^2.3.2 | Ajustes locales |
| Conectividad | `connectivity_plus` ^6.0.3 | Estado de red |
| i18n | `LanguageService` propio | ChangeNotifier, sin intl package |

---

## 4. Estructura de Archivos

```
curbradar_frontend/
├── pubspec.yaml                          ← Dependencias (NO agregar cloud_firestore ni firebase_storage)
├── CLAUDE.md                             ← Este archivo
├── .gitignore                            ← Excluye google-services.json, .env, build/
└── lib/
    ├── main.dart                         ← Entry point: Firebase init, FCM, LanguageService
    ├── core/
    │   ├── config/
    │   │   ├── api_config.dart           ← ⭐ URLs del backend + endpoints (dev/prod)
    │   │   └── routes.dart              ← Todas las rutas nombradas de la app
    │   ├── models/
    │   │   ├── curb_object.dart          ← ⭐ Modelo principal: objeto en la calle
    │   │   ├── user_model.dart           ← Usuario con gamificación
    │   │   ├── filter_model.dart         ← Filtros del mapa (categoría, estado, tiempo)
    │   │   ├── comment_model.dart        ← Comentarios en objetos
    │   │   ├── report_model.dart         ← Reportes de moderación
    │   │   └── request_model.dart        ← "Se busca" — búsquedas de objetos
    │   ├── services/
    │   │   ├── api_service.dart          ← ⭐ Dio singleton + auto-inject del Firebase ID Token
    │   │   ├── auth_service.dart         ← Firebase Auth → POST /auth/verify al backend
    │   │   ├── socket_service.dart       ← ⭐ Socket.io singleton — reemplaza Firestore Streams
    │   │   ├── objects_service.dart      ← CRUD objetos via REST
    │   │   ├── users_service.dart        ← Perfil, ranking, favoritos, ubicación via REST
    │   │   ├── chat_service.dart         ← Historial chat REST + modelo ChatMessage
    │   │   ├── alerts_service.dart       ← Alertas de proximidad REST + modelo AlertModel
    │   │   ├── upload_service.dart       ← Sube imagen al backend (nunca directo a Storage)
    │   │   ├── notification_service.dart ← FCM + flutter_local_notifications
    │   │   ├── proximity_service.dart    ← Radar GPS local (<500m → alerta)
    │   │   ├── location_service.dart     ← GPS en tiempo real del usuario
    │   │   ├── connectivity_service.dart ← Estado de la conexión de red
    │   │   └── language_service.dart     ← i18n multiidioma (ChangeNotifier singleton)
    │   ├── theme/
    │   │   └── app_theme.dart            ← Paleta naranja + blanco, Material 3
    │   ├── localization/
    │   │   └── app_translations.dart     ← Strings traducidos (ES, EN, ...)
    │   └── utils/
    │       └── reward_helper.dart        ← Overlay flotante "+50 XP" al ganar puntos
    └── presentation/
        └── screens/
            ├── auth/
            │   └── login_screen.dart         ← Google Sign-in + Email/Password
            ├── home/
            │   ├── splash_screen.dart        ← Carga inicial → /home o /login
            │   ├── main_navigation_screen.dart ← BottomNav: Mapa / Alertas / Publicar / Perfil
            │   ├── home_map_screen.dart       ← ⭐ Google Maps + Socket.io en tiempo real
            │   ├── object_detail_screen.dart  ← Detalle objeto + claim + confirmar + chat
            │   ├── chat_screen.dart           ← Chat en tiempo real por objeto
            │   ├── filters_screen.dart        ← Filtros: categoría / estado / distancia / tiempo
            │   └── all_nearby_objects_screen.dart ← Lista de objetos cercanos
            ├── publish/
            │   └── publish_object_screen.dart ← Formulario + cámara + UploadService
            ├── profile/
            │   ├── profile_screen.dart        ← Perfil propio + stats + editar alias
            │   ├── public_profile_screen.dart ← Perfil público de otro usuario
            │   ├── my_posts_screen.dart       ← Mis publicaciones
            │   └── admin_panel_screen.dart    ← Panel admin (solo role=admin)
            ├── ranking/
            │   └── ranking_screen.dart        ← Leaderboard por puntos
            ├── saved/
            │   └── saved_objects_screen.dart  ← Objetos guardados como favoritos
            ├── alerts/
            │   └── alerts_screen.dart         ← Historial de alertas de proximidad
            ├── onboarding/
            │   └── onboarding_screen.dart     ← Tutorial primera vez
            ├── premium/
            │   └── premium_screen.dart        ← Pantalla suscripción (futuro)
            └── settings/
                ├── settings_screen.dart
                ├── notification_settings_screen.dart
                ├── search_radius_screen.dart
                ├── privacy_settings_screen.dart
                └── language_settings_screen.dart
```

---

## 5. Servicios — API de cada uno

### 5.1 ApiService (`api_service.dart`) ⭐
**Singleton Dio.** Todos los demás servicios usan este — nunca crear `Dio()` directamente.

```dart
final _api = ApiService();

_api.get(path, queryParams: {...})
_api.post(path, data: {...})
_api.patch(path, data: {...})
_api.delete(path)
_api.uploadFile(path, filePath, fields: {...})   // multipart

// Extraer mensaje de error legible:
ApiService.extractErrorMessage(dioException)  // static
```

**Interceptor automático:** inyecta `Authorization: Bearer <Firebase ID Token>` en cada request.
Si el servidor responde **401**, refresca el token y reintenta **1 vez** automáticamente.

---

### 5.2 AuthService (`auth_service.dart`)
Flujo completo: Firebase Auth → backend MongoDB.

```dart
final _auth = AuthService();

_auth.userStream                         // Stream<User?> — estado Firebase
_auth.currentUserUid                     // String? — UID actual
_auth.signInWithGoogle(fcmToken: token)  // Google OAuth → verifica backend
_auth.signInWithEmail(email, password)   // Email/pass → verifica backend
_auth.signUpWithEmail(email, password)   // Registro → verifica backend
_auth.signOut()                          // Cierra en Firebase + POST /auth/logout
```

**Retorna:** `Map<String, dynamic>?` con el usuario MongoDB tras verificar.

---

### 5.3 SocketService (`socket_service.dart`) ⭐
**Singleton Socket.io.** Reemplaza todos los `StreamBuilder` de Firestore.

```dart
final _socket = SocketService();

// Conectar (llamar al arrancar la app o al entrar al mapa)
await _socket.connect();
_socket.isConnected  // bool

// Salas
_socket.joinMap()                    // Recibir object:new / object:updated / object:deleted
_socket.leaveMap()
_socket.joinObject(objectId)         // Chat + cambios del objeto en detalle
_socket.leaveObject(objectId)
_socket.joinHunters()                // Ver ubicación de otros cazadores

// Eventos
_socket.on('object:new', (data) { ... })       // Escuchar
_socket.off('object:new')                      // Dejar de escuchar
_socket.once('object:new', (data) { ... })     // Una sola vez

// Enviar ubicación propia
_socket.updateMyLocation(lat, lng)
```

**Eventos que llegan del servidor:**

| Evento | Payload | Cuándo |
|--------|---------|--------|
| `object:new` | `{ object }` | Nuevo objeto publicado |
| `object:updated` | `{ objectId, status, ... }` | Cambio de estado / ETA |
| `object:deleted` | `{ objectId }` | Objeto recogido o expirado |
| `hunter:location` | `{ firebaseUid, lat, lng }` | Cazador movió su posición |
| `newMessage` | `{ message }` | Nuevo mensaje de chat |

**⚠️ NUNCA desconectar el singleton en `dispose()` de una pantalla** — solo salir de la sala:
```dart
@override
void dispose() {
  _socket.leaveMap();       // ✅ correcto
  // _socket.disconnect(); ← ❌ rompe el socket para toda la app
  super.dispose();
}
```

---

### 5.4 ObjectsService (`objects_service.dart`)

```dart
final _objects = ObjectsService();

// Cargar objetos cercanos (para el mapa)
List<CurbObject> objects = await _objects.getNearbyObjects(
  lat: lat, lng: lng,
  radiusMeters: 5000,
  category: 'Muebles',   // opcional
  status: 'available',   // opcional
  timeRange: '24h',      // opcional
  searchQuery: 'sofá',   // opcional
);

_objects.getObjectById(id)             // CurbObject?
_objects.createObject(data)            // CurbObject
_objects.updateStatus(id, 'onMyWay')   // void — emite Socket object:updated
_objects.confirmStillThere(id)         // bool (true = primera vez)
_objects.updateEta(id, '20 minutos')   // void
_objects.reportObject(id, reason)      // void
```

---

### 5.5 UsersService (`users_service.dart`)

```dart
final _users = UsersService();

_users.getMyProfile()                           // UserModel?
_users.updateProfile(username: 'x', profileImageUrl: 'url') // UserModel?
_users.updateLocation(lat, lng, isOnline: true) // void (silencioso si falla)
_users.getRanking(limit: 50)                    // List<UserModel>
_users.getPublicProfile(firebaseUid)            // UserModel?
_users.toggleFavorite(objectId, isFavorite: true) // void
_users.getFavoriteObjects()                     // List<CurbObject>
_users.getMyObjects()                           // List<CurbObject>
_users.getActiveHunters()                       // List<UserModel>
```

---

### 5.6 ChatService (`chat_service.dart`)
El modelo `ChatMessage` está definido dentro de este mismo archivo.

```dart
final _chat = ChatService();

// Historial (REST)
List<ChatMessage> msgs = await _chat.getMessages(objectId);

// Enviar mensaje (REST — el backend emite 'newMessage' via Socket.io)
ChatMessage sent = await _chat.sendMessage(objectId, text);

// Escuchar mensajes en tiempo real (via SocketService — recomendado)
_socket.joinObject(objectId);
_socket.on('newMessage', (data) {
  final msg = ChatMessage.fromJson(data['message']);
  setState(() => _messages.add(msg));
});
```

---

### 5.7 AlertsService (`alerts_service.dart`)
El modelo `AlertModel` está definido dentro de este mismo archivo.

```dart
final _alerts = AlertsService();

List<AlertModel> alerts = await _alerts.getMyAlerts();
_alerts.markAsRead(alertId);   // void — silencioso
_alerts.markAllAsRead();       // void — silencioso
```

---

### 5.8 UploadService (`upload_service.dart`)
**El cliente NUNCA toca Firebase Storage directamente.**

```dart
final _upload = UploadService();

// Subir foto de objeto
final String url = await _upload.uploadObjectImage(File(pickedFile.path));

// Subir foto de perfil
final String url = await _upload.uploadProfileImage(File(pickedFile.path));
// La URL retornada es pública en Firebase Storage (https://storage.googleapis.com/...)
```

Formatos soportados: `.jpg`, `.jpeg`, `.png`, `.webp`.

---

### 5.9 NotificationService (`notification_service.dart`)
Igual que en el backup. Maneja FCM + notificaciones locales. No toca Firestore.

```dart
await NotificationService().init();  // Llamado en main.dart
// El FCM token se pasa a AuthService.signIn*() y se envía al backend en /auth/verify
```

---

### 5.10 ProximityService (`proximity_service.dart`)
Radar local: escucha GPS del usuario y compara contra los objetos del mapa.

- Objetos a **< 500 metros** → lanza notificación local
- Guarda set de IDs ya notificados para evitar spam
- No llama a Firestore — usa la lista de `ObjectsService`

---

### 5.11 LanguageService (`language_service.dart`)
`ChangeNotifier` singleton. Controla el idioma de la app.

```dart
LanguageService().currentLanguage   // 'es' | 'en' | ...
LanguageService().init()            // Llamado en main.dart
// La app escucha con ListenableBuilder en main.dart
```

---

## 6. Modelos — Campos y Comportamiento

### 6.1 CurbObject (`curb_object.dart`)

```dart
CurbObject {
  String id               // Normalizado desde '_id' de MongoDB
  String title
  String description
  String category         // 'Muebles' | 'Electrodomésticos' | 'Electrónica' | 'Ropa' | 'Juguetes' | 'Otros'
  List<String> imageUrls
  double latitude         // Ya descompuesto por el backend (NO GeoJSON)
  double longitude
  String address
  String? locality
  CurbObjectStatus status // available | onMyWay | pickedUp
  String postedByUserId
  String postedByUserName
  DateTime createdAt      // Parseado desde ISO8601
  DateTime updatedAt
  DateTime lastConfirmedAt
  String? claimedByUserId
  String? claimedByUserName
  DateTime? claimedAt
  String? claimedUserEta
  int views
  int confirmations
  double estimatedValue   // USD del objeto
  bool isChatEnabled
  DateTime? lastMessageAt
  String? lastMessageBy
}

// Getters útiles:
obj.isExpired             // bool — lastConfirmedAt > 48h
obj.isClaimExpired        // bool — claimedAt > 2h
obj.remainingTimeText     // '47h 30m' | 'Expirado'
obj.remainingClaimTimeText // '01:45:22' (para onMyWay)

// Crear desde JSON del backend:
CurbObject.fromJson(json)   // maneja '_id' o 'id', fechas ISO8601
obj.toJson()                // solo campos editables (para POST)
obj.copyWith(status: 'onMyWay', ...)  // actualización local inmediata
```

**Estados del objeto:**
```
available → onMyWay → (pickedUp → soft delete en backend)
    ↑_____ claim expira en 2h (auto-reset)
```

### 6.2 UserModel (`user_model.dart`)

```dart
UserModel {
  String id               // MongoDB _id
  String firebaseUid      // Firebase Auth UID — el identificador real entre sistemas
  String name             // Nombre real (de Google o registro)
  String username         // Alias elegido por el usuario
  String email
  String profileImageUrl
  int points
  int level               // floor(points / 500) + 1
  String levelTitle       // Explorador | Cazador | Experto | Leyenda
  int postsCount
  int foundCount
  int confirmationsCount
  double totalImpactValue // USD total de objetos recogidos
  List<String> favorites  // IDs de objetos favoritos
  bool isOnline
  double? latitude
  double? longitude
  String role             // 'user' | 'admin'
}

// Getters:
user.displayName   // username ?? 'Cazador Anónimo'
user.isAdmin       // role == 'admin'
user.reliability   // double (%) — fiabilidad basada en confirmaciones
```

### 6.3 ChatMessage (en `chat_service.dart`)

```dart
ChatMessage {
  String id          // MongoDB _id
  String objectId
  String senderId    // firebaseUid del emisor
  String senderName
  String senderImageUrl
  String text
  DateTime createdAt
}
ChatMessage.fromJson(json)  // parsea '_id', fecha ISO8601
```

### 6.4 AlertModel (en `alerts_service.dart`)

```dart
AlertModel {
  String id
  String objectId
  String objectTitle
  String objectImageUrl
  String address
  double distance         // en metros
  DateTime createdAt
  bool isRead
}
AlertModel.fromJson(json)
```

### 6.5 Otros modelos (`filter_model.dart`, `comment_model.dart`, `report_model.dart`, `request_model.dart`)
Disponibles en `lib/core/models/`. Usar `fromJson` / `toJson` estándar, sin `Timestamp`.

---

## 7. Configuración y Entornos (`api_config.dart`)

```dart
ApiConfig.baseUrl    // 'http://localhost:3000/api'  (dev)
                     // 'https://api.curbradar.tech/api'  (prod)
ApiConfig.wsUrl      // 'ws://localhost:3000'  (dev)
                     // 'wss://api.curbradar.tech'  (prod)

// Endpoints predefinidos:
ApiConfig.authVerify    // '/auth/verify'
ApiConfig.authLogout    // '/auth/logout'
ApiConfig.objects       // '/objects'
ApiConfig.users         // '/users'
ApiConfig.chat          // '/chat'
ApiConfig.alerts        // '/alerts'
ApiConfig.requests      // '/requests'
ApiConfig.admin         // '/admin'
ApiConfig.upload        // '/upload'
```

**Cambiar de entorno al compilar:**
```bash
# Desarrollo (default)
flutter run

# Producción
flutter run --dart-define=ENVIRONMENT=production
flutter build apk --dart-define=ENVIRONMENT=production
flutter build ios --dart-define=ENVIRONMENT=production
flutter build appbundle --dart-define=ENVIRONMENT=production
```

---

## 8. Rutas de Navegación (`routes.dart`)

| Constante | Ruta | Pantalla | Args |
|-----------|------|----------|------|
| `AppRoutes.splash` | `/` | SplashScreen | — |
| `AppRoutes.onboarding` | `/onboarding` | OnboardingScreen | — |
| `AppRoutes.login` | `/login` | LoginScreen | — |
| `AppRoutes.home` | `/home` | MainNavigationScreen | — |
| `AppRoutes.publish` | `/publish` | PublishObjectScreen | — |
| `AppRoutes.objectDetail` | `/object-detail` | ObjectDetailScreen | `CurbObject` via `ModalRoute` |
| `AppRoutes.chat` | `/chat` | ChatScreen | `CurbObject` via `ModalRoute` |
| `AppRoutes.publicProfile` | `/public_profile` | PublicProfileScreen | `String firebaseUid` via `ModalRoute` |
| `AppRoutes.allNearby` | `/all-nearby` | AllNearbyObjectsScreen | `{objects, position}` via `ModalRoute` |
| `AppRoutes.filters` | `/filters` | FiltersScreen | `FilterModel` como constructor arg |
| `AppRoutes.ranking` | `/ranking` | RankingScreen | — |
| `AppRoutes.saved` | `/saved` | SavedObjectsScreen | — |
| `AppRoutes.myPosts` | `/my-posts` | MyPostsScreen | — |
| `AppRoutes.adminPanel` | `/admin-panel` | AdminPanelScreen | — |
| `AppRoutes.settings` | `/settings` | SettingsScreen | — |
| `AppRoutes.notificationSettings` | `/notification-settings` | NotificationSettingsScreen | — |
| `AppRoutes.searchRadiusSettings` | `/search-radius-settings` | SearchRadiusScreen | — |
| `AppRoutes.privacySettings` | `/privacy-settings` | PrivacySettingsScreen | — |
| `AppRoutes.languageSettings` | `/language-settings` | LanguageSettingsScreen | — |
| `AppRoutes.premium` | `/premium` | PremiumScreen | — |

**Cómo pasar argumentos y recibirlos:**
```dart
// Enviar:
Navigator.pushNamed(context, AppRoutes.objectDetail, arguments: curbObject);

// Recibir (en la pantalla con const constructor):
final obj = ModalRoute.of(context)!.settings.arguments as CurbObject;
```

---

## 9. Patrones de Código — Cómo hacer las cosas

### 9.1 Patrón estándar de una pantalla con datos REST

```dart
class MiPantallaState extends State<MiPantalla> {
  bool _isLoading = true;
  String? _error;
  List<CurbObject> _items = [];

  final _objectsService = ObjectsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final items = await _objectsService.getNearbyObjects(lat: lat, lng: lng);
      setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return ListView.builder(itemCount: _items.length, itemBuilder: ...);
  }
}
```

### 9.2 Patrón estándar para Socket.io en una pantalla

```dart
final _socket = SocketService();

@override
void initState() {
  super.initState();
  _loadObjects();          // Carga inicial REST
  _socket.connect();       // Conectar si no está conectado
  _socket.joinMap();       // Entrar a sala del mapa

  _socket.on('object:new', (data) {
    final obj = CurbObject.fromJson(data['object']);
    setState(() => _objects.add(obj));
  });

  _socket.on('object:updated', (data) {
    final id = data['objectId'] as String;
    final updated = _objects.indexWhere((o) => o.id == id);
    if (updated != -1) {
      setState(() {
        _objects[updated] = _objects[updated].copyWith(
          status: data['status'],
        );
      });
    }
  });

  _socket.on('object:deleted', (data) {
    final id = data['objectId'] as String;
    setState(() => _objects.removeWhere((o) => o.id == id));
  });
}

@override
void dispose() {
  _socket.leaveMap();   // ⚠️ solo salir de la sala, NUNCA disconnect()
  _socket.off('object:new');
  _socket.off('object:updated');
  _socket.off('object:deleted');
  super.dispose();
}
```

### 9.3 Patrón para publicar un objeto con imagen

```dart
final _uploadService = UploadService();
final _objectsService = ObjectsService();

Future<void> _publish() async {
  // 1. Elegir imagen
  final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
  if (picked == null) return;

  // 2. Subir imagen al backend → devuelve URL de Firebase Storage
  final String imageUrl = await _uploadService.uploadObjectImage(File(picked.path));

  // 3. Crear objeto en el backend
  final obj = await _objectsService.createObject({
    'title': _titleController.text,
    'description': _descController.text,
    'category': _selectedCategory,
    'imageUrls': [imageUrl],
    'latitude': _currentPosition.latitude,
    'longitude': _currentPosition.longitude,
    'address': _address,
    'estimatedValue': _estimatedValue,
  });
  // El backend emite 'object:new' via Socket.io a todos los que están en la sala 'map'
}
```

### 9.4 Patrón para reclamar un objeto (claim onMyWay)

```dart
Future<void> _claimObject(CurbObject obj) async {
  try {
    await _objectsService.updateStatus(obj.id, 'onMyWay');
    // El backend emite 'object:updated' via Socket → el mapa se actualiza automáticamente
    // Actualizar el estado local inmediatamente para la UI:
    setState(() => _object = _object.copyWith(status: 'onMyWay'));
  } catch (e) {
    // Mostrar error (ej: ya hay otro claim activo)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
```

---

## 10. UI / Design System

```
Color Primario:    #FF8A00  (naranja vibrante)
Background:        #FFFFFF  (blanco puro)
Texto principal:   #121212  (casi negro)
Gris claro:        #F5F5F5
```

- **Material Design 3** — `useMaterial3: true` en `AppTheme.light`
- **Shimmer** para skeleton loading en listas
- **Confetti** al conseguir logros (nivel nuevo, primer objeto)
- **RewardHelper** — overlay `+50 XP` flotante al ganar puntos
- **Google Maps** como mapa base con markers circulares (foto del publicador)
- `AppTheme.light` definido en `lib/core/theme/app_theme.dart`

---

## 11. main.dart — Entry Point

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();          // Solo Auth + Messaging
  await LanguageService().init();          // i18n
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().init();      // FCM local
  runApp(const CurbRadarApp());
}
```

`CurbRadarApp` usa `ListenableBuilder` sobre `LanguageService()` para reconstruir
cuando cambia el idioma. Punto de entrada de rutas: `AppRoutes.splash`.

---

## 12. Reglas CRÍTICAS — Nunca Violar

### ❌ NUNCA hacer esto:

```dart
// 1. Importar paquetes prohibidos
import 'package:cloud_firestore/cloud_firestore.dart';    // ❌
import 'package:firebase_storage/firebase_storage.dart';  // ❌
import 'package:google_generative_ai/google_generative_ai.dart'; // ❌

// 2. Crear Dio directamente (siempre usar ApiService)
final dio = Dio();    // ❌
dio.get('http://...');

// 3. Usar Firestore Timestamp
Timestamp.fromDate(DateTime.now());   // ❌
Timestamp.now();                      // ❌

// 4. Hardcodear IDs o keys
const geminiApiKey = 'AIza...';       // ❌
const mapsApiKey = 'AIza...';         // ❌

// 5. Hacer polling con Timer (usar Socket.io)
Timer.periodic(Duration(seconds: 5), (_) => _loadObjects()); // ❌

// 6. Confiar en el cliente para puntos o estados
setState(() => _points += 50);   // ❌ — el backend calcula y retorna los puntos reales

// 7. Desconectar el socket en dispose() de una pantalla
_socket.disconnect();   // ❌ — rompe el socket para toda la app
```

### ✅ SIEMPRE hacer esto:

```dart
// Fechas: DateTime + ISO8601
DateTime.parse(json['createdAt']);         // ✅
DateFormat.format(dateTime);               // ✅

// IDs de objetos: siempre del JSON '_id' o 'id'
CurbObject.fromJson(json);  // ✅ — normaliza automáticamente

// HTTP: siempre via ApiService (inyecta el token)
final _api = ApiService();
_api.get('/objects');  // ✅

// Tiempo real: siempre via SocketService
_socket.on('object:new', handler);  // ✅

// Imágenes: siempre via UploadService
_uploadService.uploadObjectImage(file);  // ✅

// Salir de sala en dispose (no desconectar)
_socket.leaveMap();    // ✅
_socket.off('event');  // ✅
```

---

## 13. Pantallas — Qué hace cada una y de dónde saca los datos

| Pantalla | Datos via REST | Datos via Socket | Args recibidos |
|----------|---------------|-----------------|----------------|
| `home_map_screen` | `ObjectsService.getNearbyObjects()` | `object:new`, `object:updated`, `object:deleted`, `hunter:location` | — |
| `object_detail_screen` | `ObjectsService.getObjectById()`, `ObjectsService.getObjectById().comments` | `object:updated`, `object:deleted`, `newMessage` | `CurbObject` |
| `chat_screen` | `ChatService.getMessages()` | `newMessage` (via `joinObject`) | `CurbObject` |
| `publish_object_screen` | `ObjectsService.createObject()` | — (backend emite `object:new`) | — |
| `profile_screen` | `UsersService.getMyProfile()`, `UsersService.getMyObjects()` | — | — |
| `public_profile_screen` | `UsersService.getPublicProfile(uid)` | — | `String firebaseUid` |
| `ranking_screen` | `UsersService.getRanking()` | — | — |
| `saved_objects_screen` | `UsersService.getFavoriteObjects()` | — | — |
| `my_posts_screen` | `UsersService.getMyObjects()` | — | — |
| `alerts_screen` | `AlertsService.getMyAlerts()` | — | — |
| `admin_panel_screen` | `ApiService.get('/admin/reports')`, etc. | — | — |
| `all_nearby_objects_screen` | recibe lista ya cargada | — | `{objects, position}` |
| `filters_screen` | — (UI local) | — | `FilterModel` |

---

## 14. Checklist para Agregar una Nueva Pantalla

Cuando migres o crees una pantalla nueva:

- [ ] No importa `cloud_firestore`, `firebase_storage` ni `google_generative_ai`
- [ ] No crea `Dio()` directamente — usa `ApiService()`
- [ ] No usa `Timestamp` — usa `DateTime.parse()`
- [ ] No hace polling con `Timer` — usa `SocketService.on()`
- [ ] En `dispose()` solo llama `_socket.leaveMap()` / `_socket.off()`, nunca `disconnect()`
- [ ] El ID del objeto viene de `CurbObject.id` (ya normalizado desde `_id`)
- [ ] Las imágenes se suben via `UploadService`, no directo a Storage
- [ ] Agrega la ruta en `AppRoutes` si es una pantalla nueva
- [ ] Usa `Shimmer` para el estado de carga

---

## 15. Configuración de Firebase (solo Auth + FCM)

Los archivos de credenciales van en el proyecto pero **no se commitean** (`.gitignore`):

| Archivo | Ubicación | Para qué |
|---------|-----------|---------|
| `google-services.json` | `android/app/` | Firebase Auth + FCM en Android |
| `GoogleService-Info.plist` | `ios/Runner/` | Firebase Auth + FCM en iOS |

Obtenerlos desde: [Firebase Console](https://console.firebase.google.com/project/curbradar-6d8f0/settings/general)

**Firebase Project ID:** `curbradar-6d8f0`

> ⚠️ Estos archivos son para `firebase_auth` y `firebase_messaging` solamente.
> `cloud_firestore` y `firebase_storage` **no están en el pubspec** — no se usan.

---

*Actualizado: Mayo 2026 — curbradar_frontend v1.0.0*

---

## 16. Changelog

### 2026-05-26 — Setup inicial producción + App Store

**Android:**
- `android/key.properties` creado (excluido de git) con keystore en `~/curbradar_release.jks`
- `android/app/build.gradle.kts` — signing config release con keystore
- AAB v1.0.0 (build 1) generado en `build/app/outputs/bundle/release/app-release.aab` (59.9MB)
- Subido a Google Play Console → track de prueba interna

**iOS:**
- `ios/Podfile` — deployment target subido a 15.0 (requerido por firebase_auth)
- `ios/Runner.xcodeproj/project.pbxproj` — bundle ID cambiado a `com.venturesflstudio.curbRadar`, `DEVELOPMENT_TEAM = P39356P7FN`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0`
- `ios/Runner.xcodeproj/project.pbxproj` — `TARGETED_DEVICE_FAMILY = "1"` (iPhone-only, elimina necesidad de capturas iPad)
- `ios/ExportOptions.plist` — método `app-store`, teamID `P39356P7FN`
- `GoogleService-Info.plist` — debe estar añadido al target Runner en Xcode (no solo en el directorio)
- Perfil de aprovisionamiento: `CurbRadar AppStore` (Distribution, App Store Connect) — descargar de developer.apple.com si se borra el Keychain
- IPA v1.0.0 (build 2) subido a App Store Connect via Xcode Organizer → Distribute App

**Paquetes añadidos (pubspec.yaml):**
- `flutter_image_compress: ^2.3.0` — compresión antes de subir (75% quality, max 1200px)
- `path_provider: ^2.1.4` — directorio temporal para imagen comprimida

**Bug fixes:**
- `upload_service.dart` — token Firebase siempre era null; corregido con `user.getIdToken(false)`

**App Store Connect (app ID: 6773447435):**
- Bundle ID: `com.venturesflstudio.curbRadar`
- Categoría: Lifestyle | Edad: 4+ | Precio: Gratuita
- Privacy policy: `https://curbradar.tech/privacy.html`
- App Privacy: Ubicación precisa/aproximada, Email, Fotos, ID dispositivo
