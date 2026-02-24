# Dental Integral

Base Flutter con arquitectura modular inicial (Clean + Feature First) para evolucionar por módulos.

## Base técnica implementada

- DI con `get_it`
- Navegación centralizada con `go_router`
- Bootstrap de app y manejo global de errores
- Inicialización de Firebase con estado de éxito/fallo en arranque

## Estructura inicial

- `lib/app`: bootstrap, DI y router
- `lib/core`: errores y configuración técnica compartida
- `lib/features/auth`: módulo de autenticación (domain/data/presentation)
- `lib/features/home`: primer feature de presentación para validar arranque

## Sprint 1 implementado (Auth)

- Login con correo y contraseña
- Restablecimiento de contraseña por correo
- Cierre de sesión
- Guards de rutas con `go_router`:
	- sin Firebase: pantalla técnica de configuración
	- sin sesión: redirección a login
	- con sesión: acceso a home

## Sprint 2 base implementada (Admin)

- Guard de navegación para ruta admin basado en custom claim `role=admin`
- Flujo sin costo: altas de usuarios por script local de administrador
- Asignación de módulos en Firestore al momento de crear usuario

## Sprint 3A implementado (Gestión de usuarios y permisos)

- Lectura dinámica de estado y módulos desde `users/{uid}` en Firestore
- Guards de navegación por estado activo/inactivo
- Guards por permisos de página (ejemplo: `patients`)
- Pantalla de gestión de usuarios para admin:
	- listado de usuarios
	- activar/inactivar usuario
	- editar módulos/permisos

## Modo sin costo (recomendado)

La app mantiene autenticación y permisos sin desplegar Cloud Functions.

### Crear usuarios staff sin Blaze

Usar el script local en `scripts/admin/create_staff_user.js` con una cuenta de servicio.

Antes de ejecutar, en Firebase Console activa:

- Authentication > Get started
- Sign-in method > Email/Password (habilitado)

1. `cd scripts/admin`
2. `npm install`
3. Ejecutar:

`node create_staff_user.js --serviceAccount=./serviceAccount.json --email=user@dominio.com --password=Temp12345 --displayName="Nombre Usuario" --modules=dashboard,patients`

Este script:

- Crea el usuario en Firebase Authentication
- Asigna claim `role=staff`
- Guarda perfil y módulos en colección `users`
- Registra auditoría en `audit_logs`

### Promover usuario a admin o cambiar permisos

Script local:

`node set_user_role.js --serviceAccount=./serviceAccount.json --email=user@dominio.com --role=admin --active=true --modules=dashboard,patients,appointments,billing,inventory,reports`

Notas:

- El acceso a gestión de usuarios en la app depende de claim `role=admin`.
- Si cambias el rol, cierra sesión y vuelve a iniciar para refrescar token/claims.

## Backend Firebase (opcional con Blaze)

### Prerrequisitos

1. Tener Node.js 20 instalado
2. Instalar Firebase CLI
3. Tener el proyecto Firebase en plan Blaze (requerido por Cloud Functions v2 y Secret Manager)
3. En la carpeta raíz del proyecto, ejecutar:
	- `cd functions`
	- `npm install`

### Configurar secreto para bootstrap de admin inicial

Desde la raíz del proyecto:

- `firebase functions:secrets:set INIT_ADMIN_KEY`

### Desplegar backend

Desde la raíz del proyecto:

- `firebase deploy --only functions,firestore:rules`

### Crear admin inicial (una sola vez)

Llamar la función callable `bootstrapCreateInitialAdmin` con:

- `email`
- `temporaryPassword`
- `displayName`
- `bootstrapKey` (valor del secreto)

Notas:

- Si ya existe un admin en Firestore, esta función se bloquea.
- Después del bootstrap, usar `adminCreateUser` para altas de staff.

## Firebase

La app ya intenta inicializar Firebase en el arranque usando `firebase_core`.

Para completar configuración real por plataforma, ejecutar:

1. `dart pub global activate flutterfire_cli`
2. `flutterfire configure`

Eso generará `lib/firebase_options.dart` y archivos de plataforma.
