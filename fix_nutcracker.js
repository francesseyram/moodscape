const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function fix() {
  await db.collection('playlists').doc('nutcracker')
    .collection('tracks').doc('track1')
    .update({ title: 'Waltz of the Flowers' });

  await db.collection('playlists').doc('nutcracker')
    .collection('tracks').doc('track2')
    .update({ title: 'Dance of the Sugar Plum Fairy' });

  console.log('✅ Nutcracker tracks updated!');
  process.exit(0);
}

fix().catch(console.error);