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

function parseModules(value, fallbackModules) {
  if (!value) {
    return fallbackModules;
  }

  const modules = value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  const invalid = modules.filter((item) => !ALLOWED_MODULES.has(item));
  if (invalid.length > 0) {
    throw new Error(`Módulos inválidos: ${invalid.join(', ')}`);
  }

  return [...new Set(modules)];
}

function usage() {
  console.log('Uso:');
  console.log('node set_user_role.js --serviceAccount=./serviceAccount.json --email=user@dominio.com --role=admin --active=true --modules=dashboard,patients,reports');
}

async function main() {
  const serviceAccountPath = readArg('serviceAccount');
  const email = readArg('email').toLowerCase();
  const role = readArg('role') || 'staff';
  const activeArg = (readArg('active') || 'true').toLowerCase();
  const modulesArg = readArg('modules');

  if (!serviceAccountPath || !email) {
    usage();
    throw new Error('Faltan argumentos requeridos.');
  }

  if (!email.includes('@')) {
    throw new Error('Correo inválido.');
  }

  if (role !== 'admin' && role !== 'staff') {
    throw new Error('El rol solo puede ser admin o staff.');
  }

  const active = activeArg === 'true';
  const defaultModules = role === 'admin' ? [...ALLOWED_MODULES] : ['dashboard'];
  const modules = parseModules(modulesArg, defaultModules);

  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const auth = admin.auth();
  const db = admin.firestore();

  const userRecord = await auth.getUserByEmail(email);

  await auth.setCustomUserClaims(userRecord.uid, { role });

  await db.collection('users').doc(userRecord.uid).set(
    {
      email,
      displayName: userRecord.displayName || email,
      role,
      active,
      modules,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: 'local-admin-script',
    },
    { merge: true },
  );

  await db.collection('audit_logs').add({
    type: 'USER_ROLE_UPDATED_LOCAL_SCRIPT',
    actorUid: 'local-admin-script',
    targetUid: userRecord.uid,
    targetEmail: email,
    role,
    active,
    modules,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('Rol y permisos actualizados correctamente.');
  console.log(`UID: ${userRecord.uid}`);
  console.log(`Email: ${email}`);
  console.log(`Role: ${role}`);
  console.log(`Active: ${active}`);
  console.log(`Modules: ${modules.join(', ')}`);
}

main().catch((error) => {
  console.error('Error actualizando rol:', error.message);
  process.exit(1);
});
