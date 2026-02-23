const admin = require('firebase-admin');

const ALLOWED_MODULES = new Set([
  'dashboard',
  'patients',
  'appointments',
  'billing',
  'inventory',
  'reports',
]);

function readArg(name) {
  const prefix = `--${name}=`;
  const entry = process.argv.find((arg) => arg.startsWith(prefix));
  return entry ? entry.slice(prefix.length).trim() : '';
}

function parseModules(value) {
  const modules = value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  const invalid = modules.filter((item) => !ALLOWED_MODULES.has(item));
  if (invalid.length > 0) {
    throw new Error(`Módulos inválidos: ${invalid.join(', ')}`);
  }

  if (modules.length === 0) {
    throw new Error('Debes proporcionar al menos un módulo en --modules.');
  }

  return [...new Set(modules)];
}

function usage() {
  console.log('Uso:');
  console.log('node create_staff_user.js --serviceAccount=./serviceAccount.json --email=user@dominio.com --password=Temp12345 --displayName="Nombre" --modules=dashboard,patients');
}

async function main() {
  const serviceAccountPath = readArg('serviceAccount');
  const email = readArg('email').toLowerCase();
  const password = readArg('password');
  const displayName = readArg('displayName');
  const modulesArg = readArg('modules');

  if (!serviceAccountPath || !email || !password || !displayName || !modulesArg) {
    usage();
    throw new Error('Faltan argumentos requeridos.');
  }

  if (!email.includes('@')) {
    throw new Error('Correo inválido.');
  }

  if (password.length < 8) {
    throw new Error('La contraseña debe tener al menos 8 caracteres.');
  }

  const modules = parseModules(modulesArg);

  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const auth = admin.auth();
  const db = admin.firestore();

  let userRecord;
  let createdNewUser = false;

  try {
    userRecord = await auth.createUser({
      email,
      password,
      displayName,
      emailVerified: false,
      disabled: false,
    });
    createdNewUser = true;
  } catch (error) {
    if (error.code !== 'auth/email-already-exists') {
      throw error;
    }

    userRecord = await auth.getUserByEmail(email);
    await auth.updateUser(userRecord.uid, {
      displayName,
      disabled: false,
    });
    userRecord = await auth.getUser(userRecord.uid);
  }

  await auth.setCustomUserClaims(userRecord.uid, { role: 'staff' });

  let firestoreSaved = true;
  try {
    await db.collection('users').doc(userRecord.uid).set({
      email,
      displayName,
      role: 'staff',
      modules,
      active: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'local-admin-script',
    });

    await db.collection('audit_logs').add({
      type: 'USER_CREATED_LOCAL_SCRIPT',
      actorUid: 'local-admin-script',
      targetUid: userRecord.uid,
      targetEmail: email,
      modules,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    firestoreSaved = false;
    console.warn('Advertencia: usuario creado en Auth pero no se guardó en Firestore.');
    console.warn(`Detalle: ${error.message}`);
  }

  console.log(createdNewUser
    ? 'Usuario staff creado correctamente.'
    : 'Usuario ya existente: sincronización aplicada correctamente.');
  console.log(`UID: ${userRecord.uid}`);
  console.log(`Email: ${email}`);
  console.log(`Firestore: ${firestoreSaved ? 'ok' : 'pendiente (habilitar API y reintentar sync)'}`);
}

main().catch((error) => {
  console.error('Error creando usuario:', error.message);
  process.exit(1);
});
