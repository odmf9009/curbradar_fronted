# 🧠 CLAUDE.md — curbradar_frontend

> **Lee primero** el CLAUDE.md del proyecto backup (`curb_radar_backup/CLAUDE.md`) para el contexto completo del negocio.
> Este archivo cubre exclusivamente el frontend Flutter.

---

## Arquitectura Híbrida — Qué usa Firebase directamente (GRATIS)

```
Firebase Auth     ✅ DIRECTO desde Flutter  → login Google/email, ID Token
Firebase FCM      ✅ DIRECTO desde Flutter  → recepción de push notifications
─────────────────────────────────────────────────────────────────────────────
Firestore         ❌ NO USAR               → reemplazado por REST + Socket.io
Firebase Storage  ❌ NO USAR desde cliente → el BACKEND sube las imágenes
cloud_generative_ai ❌ NO USAR             → Gemini corre en el backend
```

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter (Dart) |
| Auth | Firebase Auth → ID Token → backend verifica |
| Tiempo real | **Socket.io** (`socket_io_client`) → reemplaza Firestore Streams |
| API REST | Dio (con auto-inject del Firebase ID Token) |
| Push (recepción) | Firebase Messaging + flutter_local_notifications |
| Imágenes (upload) | `UploadService` → POST al backend → Firebase Storage |
| Mapas | Google Maps Flutter |

---

## Diferencia CLAVE con el Backup Original

| Backup (Firestore directo) | Frontend nuevo (híbrido) |
|---------------------------|--------------------------|
| `cloud_firestore` dependency | ❌ ELIMINADA |
| `FirestoreService` con Streams | ✅ `ObjectsService` + `SocketService` |
| `firebase_storage` dependency | ❌ ELIMINADA (sube el backend) |
| `google_generative_ai` dependency | ❌ ELIMINADA (Gemini en backend) |
| `Timestamp.fromDate()` | ✅ `DateTime` + ISO8601 string |
| API keys hardcodeadas en Flutter | ❌ ELIMINADAS (en .env del backend) |
| Streams en tiempo real | ✅ `SocketService.on('object:updated', ...)` |

---

## Estructura de Servicios

```
lib/core/services/
├── api_service.dart        ← ⭐ HTTP client base (Dio singleton + auto-token Firebase)
├── auth_service.dart       ← Firebase Auth login → verifica en backend
├── socket_service.dart     ← ⭐ Socket.io — reemplaza Firestore Streams
├── objects_service.dart    ← CRUD objetos via REST
├── users_service.dart      ← Perfil, ranking, favoritos via REST
├── chat_service.dart       ← Historial chat via REST (mensajes RT via Socket)
├── upload_service.dart     ← Sube imagen al BACKEND (no directo a Storage)
├── notification_service.dart ← FCM recepción + notificaciones locales (igual que backup)
├── proximity_service.dart  ← Radar GPS local (llama a ObjectsService para la lista)
├── location_service.dart   ← GPS en tiempo real (igual que backup)
└── language_service.dart   ← i18n multiidioma (igual que backup)
```

---

## Cómo usar Socket.io en una pantalla

```dart
// En initState:
final _socket = SocketService();

@override
void initState() {
  super.initState();
  _socket.connect();
  _socket.joinMap();

  // Nuevo objeto aparece en el mapa
  _socket.on('object:new', (data) {
    final obj = CurbObject.fromJson(data['object']);
    setState(() => _objects.add(obj));
  });

  // Objeto cambia de estado (available / onMyWay)
  _socket.on('object:updated', (data) {
    // Actualizar el objeto en la lista local
  });

  // Objeto recogido → quitarlo del mapa
  _socket.on('object:deleted', (data) {
    final id = data['objectId'];
    setState(() => _objects.removeWhere((o) => o.id == id));
  });
}

@override
void dispose() {
  _socket.leaveMap();
  // NO desconectar el singleton aquí — solo salir de la sala
  super.dispose();
}
```

---

## Cómo subir una imagen

```dart
// En publish_object_screen.dart:
final _uploadService = UploadService();

// 1. Elegir imagen con image_picker
final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
if (picked == null) return;

// 2. Subir al backend (que la sube a Firebase Storage)
final String imageUrl = await _uploadService.uploadObjectImage(File(picked.path));

// 3. Usar la URL en el payload del objeto
await _objectsService.createObject({
  'title': ...,
  'imageUrls': [imageUrl],   // URL pública de Firebase Storage
  ...
});
```

---

## URLs del Backend

Ver `lib/core/config/api_config.dart`

| Entorno | URL API | URL WebSocket |
|---------|---------|---------------|
| Desarrollo | `http://localhost:3000/api` | `ws://localhost:3000` |
| Producción | `https://api.curbradar.tech/api` | `wss://api.curbradar.tech` |

Compilar para producción:
```bash
flutter build apk --dart-define=ENVIRONMENT=production
flutter build ios --dart-define=ENVIRONMENT=production
```

---

## Reglas CRÍTICAS — Nunca violar

1. **NUNCA importar `cloud_firestore`** — toda la BD va via REST API
2. **NUNCA importar `firebase_storage`** — uploads van via `UploadService`
3. **NUNCA importar `google_generative_ai`** — Gemini corre en el backend
4. **NUNCA hacer HTTP directo** — siempre via `ApiService` (inyecta token automáticamente)
5. **IDs de objetos** = campo `_id` de MongoDB (string) → `CurbObject.fromJson` lo normaliza a `id`
6. **Fechas** = ISO8601 strings del backend → `DateTime.parse()`, nunca `Timestamp`
7. **Tiempo real** = `SocketService`, nunca polling manual en un `Timer`
8. **Coordenadas** = el backend devuelve `latitude` y `longitude` como campos directos (no GeoJSON)

---

## Modelos disponibles

```
lib/core/models/
├── curb_object.dart   → CurbObject (fromJson, toJson, sin Timestamp)
└── user_model.dart    → UserModel (fromJson, sin Timestamp)
```

Los demás modelos del backup (Alert, Comment, etc.) se añaden conforme se migran las pantallas.
