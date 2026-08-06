// Inicializa Firebase (Auth + Firestore) usando los SDK vendorizados en
// js/vendor/ — nunca desde CDN, así la CSP queda toda en 'self'.
import { initializeApp } from './vendor/firebase-app.js';
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from './vendor/firebase-auth.js';
import {
  getFirestore,
  collection,
  doc,
  query,
  orderBy,
  onSnapshot,
} from './vendor/firebase-firestore.js';
import { firebaseConfig } from './firebase-config.js';

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

export {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  collection,
  doc,
  query,
  orderBy,
  onSnapshot,
};
