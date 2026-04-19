const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'moodscape-bf678.firebasestorage.app'
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

async function fixUrls() {
  console.log('🌸 Fixing track URLs...');

  const moods = ['happy', 'sad', 'calm', 'angry', 'nutcracker'];

  for (const mood of moods) {
    const tracksSnap = await db
      .collection('playlists')
      .doc(mood)
      .collection('tracks')
      .get();

    for (const doc of tracksSnap.docs) {
      const data = doc.data();
      const fileName = `${mood}_${doc.id.replace('track', '')}.mp3`;
      const filePath = `audio/${mood}/${fileName}`;

      try {
        // Get a signed download URL that actually works
        const file = bucket.file(filePath);
        const [url] = await file.getSignedUrl({
          action: 'read',
          expires: '03-01-2030',
        });

        await doc.ref.update({ storageUrl: url });
        console.log(`✅ Fixed: ${mood} → ${doc.id} → ${fileName}`);
      } catch (e) {
        console.error(`❌ Failed: ${mood} → ${fileName}:`, e.message);
      }
    }
  }

  console.log('🌸 Done!');
  process.exit(0);
}

fixUrls().catch(console.error);