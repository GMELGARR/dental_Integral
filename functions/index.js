const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const firestore = admin.firestore();
const auth = admin.auth();

const MODULES = new Set([
  'dashboard',
  'patients',
  'appointments',
  'billing',
  'inventory',
  'reports',
]);

const INIT_ADMIN_KEY = defineSecret('INIT_ADMIN_KEY');

function normalizeEmail(value) {
  return String(value ?? '').trim().toLowerCase();
}

function normalizeText(value) {
  return String(value ?? '').trim();
}

function validatePayload(data) {
  const email = normalizeEmail(data?.email);
  const temporaryPassword = String(data?.temporaryPassword ?? '');
  const displayName = normalizeText(data?.displayName);
  const rawModules = Array.isArray(data?.modules) ? data.modules : [];

  if (!email || !email.includes('@')) {
    throw new HttpsError('invalid-argument', 'Correo inválido.');
  }

  if (displayName.length < 3 || displayName.length > 80) {
    throw new HttpsError('invalid-argument', 'Nombre de usuario inválido.');
  }

  if (temporaryPassword.length < 8) {
    throw new HttpsError('invalid-argument', 'La contraseña temporal debe tener mínimo 8 caracteres.');
  }

  const modules = [...new Set(rawModules.map((entry) => normalizeText(entry)))].filter(Boolean);

  if (modules.length === 0) {
    throw new HttpsError('invalid-argument', 'Debes asignar al menos un módulo.');
  }

  const invalidModules = modules.filter((moduleKey) => !MODULES.has(moduleKey));
  if (invalidModules.length > 0) {
    throw new HttpsError('invalid-argument', `Módulos inválidos: ${invalidModules.join(', ')}`);
  }

  return {
    email,
    displayName,
    temporaryPassword,
    modules,
  };
}

async function assertAdmin(context) {
  if (!context.auth) {
    throw new HttpsError('unauthenticated', 'Debes iniciar sesión para realizar esta acción.');
  }

  const callerRole = context.auth.token?.role;
  if (callerRole !== 'admin') {
    throw new HttpsError('permission-denied', 'Solo un administrador puede crear usuarios.');
  }

  return context.auth.uid;
}

async function assertNoAdminProvisioned() {
  const adminUsers = await firestore
    .collection('users')
    .where('role', '==', 'admin')
    .limit(1)
    .get();

  if (!adminUsers.empty) {
    throw new HttpsError(
      'failed-precondition',
      'Ya existe un administrador. Usa el flujo normal de gestión de usuarios.',
    );
  }
}

exports.adminCreateUser = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (request) => {
    const adminUid = await assertAdmin(request);
    const payload = validatePayload(request.data);

    try {
      const userRecord = await auth.createUser({
        email: payload.email,
        password: payload.temporaryPassword,
        displayName: payload.displayName,
        emailVerified: false,
        disabled: false,
      });

      await auth.setCustomUserClaims(userRecord.uid, {
        role: 'staff',
      });

      await firestore.collection('users').doc(userRecord.uid).set({
        email: payload.email,
        displayName: payload.displayName,
        role: 'staff',
        modules: payload.modules,
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: adminUid,
      });

      await firestore.collection('audit_logs').add({
        type: 'USER_CREATED',
        actorUid: adminUid,
        targetUid: userRecord.uid,
        targetEmail: payload.email,
        modules: payload.modules,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        uid: userRecord.uid,
        email: payload.email,
      };
    } catch (error) {
      logger.error('adminCreateUser failed', error);

      if (error?.code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'Ya existe un usuario con ese correo.');
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError('internal', 'No se pudo crear el usuario.');
    }
  },
);

exports.bootstrapCreateInitialAdmin = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 60,
    memory: '256MiB',
    secrets: [INIT_ADMIN_KEY],
  },
  async (request) => {
    const providedKey = normalizeText(request.data?.bootstrapKey);
    if (!providedKey || providedKey !== INIT_ADMIN_KEY.value()) {
      throw new HttpsError('permission-denied', 'Bootstrap key inválida.');
    }

    await assertNoAdminProvisioned();

    const payload = validatePayload({
      email: request.data?.email,
      temporaryPassword: request.data?.temporaryPassword,
      displayName: request.data?.displayName,
      modules: [...MODULES],
    });

    try {
      const userRecord = await auth.createUser({
        email: payload.email,
        password: payload.temporaryPassword,
        displayName: payload.displayName,
        emailVerified: false,
        disabled: false,
      });

      await auth.setCustomUserClaims(userRecord.uid, {
        role: 'admin',
      });

      await firestore.collection('users').doc(userRecord.uid).set({
        email: payload.email,
        displayName: payload.displayName,
        role: 'admin',
        modules: [...MODULES],
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: 'bootstrap',
      });

      await firestore.collection('audit_logs').add({
        type: 'INITIAL_ADMIN_CREATED',
        actorUid: 'bootstrap',
        targetUid: userRecord.uid,
        targetEmail: payload.email,
        modules: [...MODULES],
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        uid: userRecord.uid,
        email: payload.email,
      };
    } catch (error) {
      logger.error('bootstrapCreateInitialAdmin failed', error);

      if (error?.code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'Ya existe un usuario con ese correo.');
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError('internal', 'No se pudo crear el administrador inicial.');
    }
  },
);
