// Configuration Firebase pour le web
// Ce fichier est nécessaire pour initialiser Firebase avant Flutter

const firebaseConfig = {
  apiKey: "AIzaSyCeHaow822KVEKczQ8rXzCVXu1likojh7U",
  authDomain: "first-pro-cheoo.firebaseapp.com",
  projectId: "first-pro-cheoo",
  storageBucket: "first-pro-cheoo.firebasestorage.app",
  messagingSenderId: "862175497641",
  appId: "1:862175497641:web:9e6cf9b7d65a38cab808b8",
  measurementId: "G-44JR4JPXWS"
};

// Initialiser Firebase si disponible
if (typeof firebase !== 'undefined') {
  firebase.initializeApp(firebaseConfig);
  console.log('✅ Firebase initialisé via firebase-config.js');
}
