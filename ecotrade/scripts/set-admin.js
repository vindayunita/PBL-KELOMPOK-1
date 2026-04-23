const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// ── Ganti dengan UID user yang ingin dijadikan admin ──────────────────────────
const TARGET_UID = 'l7hz15BXgNOJJcz3igvmKK6WjlI2';
// ─────────────────────────────────────────────────────────────────────────────

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function setAdminClaim() {
  try {
    // Set custom claim
    await admin.auth().setCustomUserClaims(TARGET_UID, { admin: true });
    console.log(`✅ Berhasil! User ${TARGET_UID} sekarang memiliki role admin.`);
    console.log('   User perlu logout lalu login ulang agar token diperbarui.');
  } catch (error) {
    console.error('❌ Gagal set custom claim:', error.message);
  } finally {
    process.exit();
  }
}

setAdminClaim();
