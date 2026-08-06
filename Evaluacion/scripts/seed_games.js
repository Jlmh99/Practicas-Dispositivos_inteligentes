// Siembra la colección `games` de Firestore con el catálogo inicial de juegos.
//
// Uso (PowerShell):
//   $env:GOOGLE_APPLICATION_CREDENTIALS="$HOME\.secrets\mindgames-admin.json"
//   node scripts/seed_games.js
//
// Idempotente: usa IDs fijos, así que correrlo varias veces sobrescribe
// los mismos 6 documentos en lugar de duplicarlos.

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    'Falta GOOGLE_APPLICATION_CREDENTIALS. Ejemplo:\n' +
      '  $env:GOOGLE_APPLICATION_CREDENTIALS="$HOME\\.secrets\\mindgames-admin.json"'
  );
  process.exit(1);
}

initializeApp({ credential: applicationDefault() });

const db = getFirestore();

// El id es fijo y descriptivo: permite referenciar un juego desde el teléfono
// (sessionState.gameId) y desde la PWA sin depender de IDs aleatorios.
const games = [
  { id: 'sudoku',      nombre: 'Sudoku',          dificultad: 'Media',   jugadas: 128, tiempoPromedioSeg: 412, estado: 'disponible'   },
  { id: 'crucigrama',  nombre: 'Crucigrama',      dificultad: 'Media',   jugadas: 96,  tiempoPromedioSeg: 530, estado: 'disponible'   },
  { id: 'sopa-letras', nombre: 'Sopa de Letras',  dificultad: 'Fácil',   jugadas: 74,  tiempoPromedioSeg: 210, estado: 'disponible'   },
  { id: 'memorama',    nombre: 'Memorama',        dificultad: 'Fácil',   jugadas: 141, tiempoPromedioSeg: 180, estado: 'disponible'   },
  { id: 'ahorcado',    nombre: 'Ahorcado',        dificultad: 'Media',   jugadas: 55,  tiempoPromedioSeg: 240, estado: 'disponible'   },
  { id: 'hanoi',       nombre: 'Torres de Hanói', dificultad: 'Difícil', jugadas: 20,  tiempoPromedioSeg: 600, estado: 'proximamente' },
];

async function seed() {
  const batch = db.batch();

  games.forEach((game, index) => {
    const ref = db.collection('games').doc(game.id);
    batch.set(ref, {
      nombre: game.nombre,
      dificultad: game.dificultad,
      jugadas: game.jugadas,
      tiempoPromedioSeg: game.tiempoPromedioSeg,
      // Ruta relativa a la carpeta de la PWA. Si el archivo no existe,
      // la TV cae al fallback (elemento evaluado en SA.2.C).
      mediaUrl: `assets/media/${game.id}.png`,
      estado: game.estado,
      orden: index + 1,
    });
  });

  await batch.commit();
  console.log(`Sembrados ${games.length} juegos en la colección "games".`);
  games.forEach((g) => console.log(`  - ${g.id}: ${g.nombre}`));
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error al sembrar juegos:', err);
    process.exit(1);
  });