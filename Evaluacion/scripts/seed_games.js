// Siembra la colección `games` de Firestore con el catálogo inicial de juegos.
//
// Uso:
//   GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/mindgames-admin.json" node scripts/seed_games.js
//
// La credencial de la cuenta de servicio NUNCA se escribe en este archivo ni en el
// repo: admin.credential.applicationDefault() la toma de la variable de entorno
// GOOGLE_APPLICATION_CREDENTIALS (ver .gitignore: *serviceAccount*.json, etc.).

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    'Falta GOOGLE_APPLICATION_CREDENTIALS. Ejemplo:\n' +
      '  GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/mindgames-admin.json" node scripts/seed_games.js'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

const games = [
  { nombre: 'Sudoku', dificultad: 'Media', jugadas: 128, tiempoPromedioSeg: 412 },
  { nombre: 'Crucigrama', dificultad: 'Media', jugadas: 96, tiempoPromedioSeg: 530 },
  { nombre: 'Sopa de Letras', dificultad: 'Fácil', jugadas: 74, tiempoPromedioSeg: 210 },
  { nombre: 'Memorama', dificultad: 'Fácil', jugadas: 141, tiempoPromedioSeg: 180 },
  { nombre: 'Ahorcado', dificultad: 'Media', jugadas: 55, tiempoPromedioSeg: 240 },
  { nombre: 'Torres de Hanói', dificultad: 'Difícil', jugadas: 20, tiempoPromedioSeg: 600 },
];

async function seed() {
  const batch = db.batch();

  games.forEach((game, index) => {
    const ref = db.collection('games').doc();
    batch.set(ref, {
      nombre: game.nombre,
      dificultad: game.dificultad,
      jugadas: game.jugadas,
      tiempoPromedioSeg: game.tiempoPromedioSeg,
      mediaUrl: '',
      estado: 'activo',
      orden: index + 1,
    });
  });

  await batch.commit();
  console.log(`Sembrados ${games.length} juegos en la colección "games".`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error al sembrar juegos:', err);
    process.exit(1);
  });
