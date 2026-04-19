const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seed() {
  console.log('🌸 Seeding MoodScape database...');

  // ── MOODS 
  const moods = [
    { id: 'happy', label: 'Happy', emoji: '😊', color: '#FFD54F', bgColor: '#FFFDE7', order: 1, isActive: true },
    { id: 'sad', label: 'Sad', emoji: '😢', color: '#90CAF9', bgColor: '#E3F2FD', order: 2, isActive: true },
    { id: 'calm', label: 'Calm', emoji: '😌', color: '#A5D6A7', bgColor: '#E8F5E9', order: 3, isActive: true },
    { id: 'angry', label: 'Angry', emoji: '😤', color: '#EF9A9A', bgColor: '#FFEBEE', order: 4, isActive: true },
    { id: 'nutcracker', label: 'Nutcracker', emoji: '🎄', color: '#CE93D8', bgColor: '#F3E5F5', order: 5, isActive: true },
  ];

  for (const mood of moods) {
    const { id, ...data } = mood;
    await db.collection('moods').doc(id).set(data);
    console.log(`✅ Mood added: ${mood.label}`);
  }

  // ── PLAYLISTS & TRACKS 
  const playlists = {
    happy: [
      { id: 'track1', title: 'Sunny Day', artist: 'MoodScape Radio', storageUrl: '', order: 1 },
      { id: 'track2', title: 'Feel Good Vibes', artist: 'MoodScape Radio', storageUrl: '', order: 2 },
    ],
    sad: [
      { id: 'track1', title: 'Gentle Rain', artist: 'MoodScape Radio', storageUrl: '', order: 1 },
      { id: 'track2', title: 'Blue Hour', artist: 'MoodScape Radio', storageUrl: '', order: 2 },
    ],
    calm: [
      { id: 'track1', title: 'Still Waters', artist: 'MoodScape Radio', storageUrl: '', order: 1 },
      { id: 'track2', title: 'Peaceful Mind', artist: 'MoodScape Radio', storageUrl: '', order: 2 },
    ],
    angry: [
      { id: 'track1', title: 'Release', artist: 'MoodScape Radio', storageUrl: '', order: 1 },
      { id: 'track2', title: 'Power Through', artist: 'MoodScape Radio', storageUrl: '', order: 2 },
    ],
    nutcracker: [
      { id: 'track1', title: 'Dance of the Sugar Plum', artist: 'Tchaikovsky', storageUrl: '', order: 1 },
      { id: 'track2', title: 'March', artist: 'Tchaikovsky', storageUrl: '', order: 2 },
    ],
  };

  for (const [moodId, tracks] of Object.entries(playlists)) {
    for (const track of tracks) {
      const { id, ...data } = track;
      await db.collection('playlists').doc(moodId).collection('tracks').doc(id).set(data);
      console.log(`✅ Track added: ${track.title} → ${moodId}`);
    }
  }

  // ── QUOTES 
  const quotes = [
    { text: 'Every day is a fresh start 🌸', author: 'Unknown', moodTag: 'happy' },
    { text: "It's okay to feel sad. Let the feelings flow.", author: 'Unknown', moodTag: 'sad' },
    { text: 'Peace begins with a single breath.', author: 'Unknown', moodTag: 'calm' },
    { text: 'Channel your energy into something powerful.', author: 'Unknown', moodTag: 'angry' },
    { text: 'Life is too short not to dance to the Nutcracker 🎄', author: 'MoodScape', moodTag: 'nutcracker' },
    { text: 'You are capable of amazing things 💪', author: 'Unknown', moodTag: 'happy' },
    { text: 'This too shall pass 🌧️', author: 'Unknown', moodTag: 'sad' },
    { text: 'Breathe in. Breathe out. All is well.', author: 'Unknown', moodTag: 'calm' },
  ];

  for (const quote of quotes) {
    await db.collection('quotes').add(quote);
    console.log(`✅ Quote added: "${quote.text.substring(0, 30)}..."`);
  }

  console.log('🌸 Database seeding complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Error seeding database:', err);
  process.exit(1);
});