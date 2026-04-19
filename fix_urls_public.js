const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'moodscape-bf678.firebasestorage.app'
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

async function fixUrls() {
  console.log('🌸 Updating to public download URLs...');

  const moods = ['happy', 'sad', 'calm', 'angry', 'nutcracker'];

  for (const mood of moods) {
    const tracksSnap = await db
      .collection('playlists')
      .doc(mood)
      .collection('tracks')
      .get();

    for (const doc of tracksSnap.docs) {
      const fileName = `${mood}_${doc.id.replace('track', '')}.mp3`;
      const filePath = `audio/${mood}/${fileName}`;
      const bucketName = 'moodscape-bf678.firebasestorage.app';

      // Public download URL format — no signing needed
      const encodedPath = encodeURIComponent(filePath);
      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media`;

      await doc.ref.update({ storageUrl: publicUrl });
      console.log(`✅ Updated: ${mood} → ${doc.id}`);
    }
  }

  console.log('🌸 Done!');
  process.exit(0);
}

fixUrls().catch(console.error);