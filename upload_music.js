const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const path = require('path');
const fs = require('fs');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'moodscape-bf678.firebasestorage.app' 
});

const bucket = admin.storage().bucket();

const files = [
  { local: 'music/happy_1.mp3', remote: 'audio/happy/happy_1.mp3' },
  { local: 'music/happy_2.mp3', remote: 'audio/happy/happy_2.mp3' },
  { local: 'music/sad_1.mp3', remote: 'audio/sad/sad_1.mp3' },
  { local: 'music/sad_2.mp3', remote: 'audio/sad/sad_2.mp3' },
  { local: 'music/calm_1.mp3', remote: 'audio/calm/calm_1.mp3' },
  { local: 'music/calm_2.mp3', remote: 'audio/calm/calm_2.mp3' },
  { local: 'music/angry_1.mp3', remote: 'audio/angry/angry_1.mp3' },
  { local: 'music/angry_2.mp3', remote: 'audio/angry/angry_2.mp3' },
  { local: 'music/nutcracker_1.mp3', remote: 'audio/nutcracker/nutcracker_1.mp3' },
  { local: 'music/nutcracker_2.mp3', remote: 'audio/nutcracker/nutcracker_2.mp3' },
];

async function uploadAll() {
  console.log('🌸 Uploading music files...');

  for (const file of files) {
    if (!fs.existsSync(file.local)) {
      console.log(`⚠️  Skipping ${file.local} — file not found`);
      continue;
    }

    await bucket.upload(file.local, {
      destination: file.remote,
      metadata: { contentType: 'audio/mpeg' },
    });

    console.log(`✅ Uploaded: ${file.local} → ${file.remote}`);
  }

  console.log('🌸 All files uploaded!');
  process.exit(0);
}

uploadAll().catch((err) => {
  console.error('❌ Upload failed:', err);
  process.exit(1);
});