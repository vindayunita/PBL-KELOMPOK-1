const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'ecotrade-119cc'
});

async function run() {
  const db = admin.firestore();
  console.log("Checking recent notifications...");
  const snapshot = await db.collection('notifications')
    .orderBy('createdAt', 'desc')
    .limit(5)
    .get();

  if (snapshot.empty) {
    console.log("No notifications found.");
    return;
  }

  snapshot.forEach(doc => {
    console.log(doc.id, "=>", doc.data());
  });
}

run().catch(console.error);
