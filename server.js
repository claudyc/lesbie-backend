require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { RtcTokenBuilder, RtcRole } = require('agora-token');

// ─── Firebase Admin Init ───────────────────────────────────────────────────
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

const db = admin.firestore();
const app = express();

// ─── Middleware ────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── Helper: Verify Firebase Token ─────────────────────────────────────────
async function verifyToken(req, res) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({
      error: 'Unauthorized — token manke',
    });
    return null;
  }

  try {
    const idToken = authHeader.split('Bearer ')[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded.uid;
  } catch {
    res.status(401).json({
      error: 'Unauthorized — token invalid',
    });
    return null;
  }
}

// ─── Public Routes ─────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🌸 Lesbie Chat Backend ap mache!',
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    ok: true,
  });
});

// ─── AI Verification: Face++ ──────────────────────────────────────────────
app.post('/verify-video-ai', async (req, res) => {
  try {
    const verifiedUid = await verifyToken(req, res);
    if (!verifiedUid) return;

    const { selfieUrl } = req.body;

    if (!selfieUrl) {
      return res.status(400).json({
        success: false,
        error: 'selfieUrl obligatwa',
      });
    }

    if (
      !process.env.FACEPP_API_KEY ||
      !process.env.FACEPP_API_SECRET
    ) {
      return res.status(500).json({
        success: false,
        error: 'Face++ pa configure sou Vercel',
      });
    }

    const form = new FormData();

    form.append('api_key', process.env.FACEPP_API_KEY);
    form.append('api_secret', process.env.FACEPP_API_SECRET);
    form.append('image_url', selfieUrl);
    form.append('return_attributes', 'gender,age');

    const faceResponse = await fetch(
      'https://api-us.faceplusplus.com/facepp/v3/detect',
      {
        method: 'POST',
        body: form,
      },
    );

    const data = await faceResponse.json();

    // ─── API Error
    if (!faceResponse.ok) {
      console.error('Face++ error:', data);

      return res.status(500).json({
        success: false,
        status: 'error',
        error:
          data?.error_message ||
          'Face++ request failed',
      });
    }

    const faces = data.faces || [];

    // ─── No Face
    if (faces.length === 0) {

      await db.collection('users')
        .doc(verifiedUid)
        .set({
          verificationStatus: 'rejected',
          isVerified: false,
          verificationReason: 'No face detected',
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      await db.collection('verification_requests')
        .doc(verifiedUid)
        .set({
          aiStatus: 'rejected',
          aiReason: 'No face detected',
          aiProvider: 'facepp',
          aiCheckedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      return res.json({
        success: false,
        status: 'rejected',
      });
    }

    // ─── Multiple Faces
    if (faces.length > 1) {

      await db.collection('users')
        .doc(verifiedUid)
        .set({
          verificationStatus: 'manual_review',
          isVerified: false,
          verificationReason:
            'Multiple faces detected',
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      await db.collection('verification_requests')
        .doc(verifiedUid)
        .set({
          aiStatus: 'manual_review',
          aiReason: 'Multiple faces detected',
          aiProvider: 'facepp',
          aiCheckedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      return res.json({
        success: false,
        status: 'manual_review',
      });
    }

    const face = faces[0];

    const gender =
      face.attributes?.gender?.value || 'Unknown';

    const age =
      face.attributes?.age?.value || 0;

    const isFemale = gender === 'Female';
    const isAdult = age >= 18;

    // ─── Uncertain AI
    if (!isFemale || !isAdult) {

      await db.collection('users')
        .doc(verifiedUid)
        .set({
          verificationStatus: 'manual_review',
          isVerified: false,
          verificationReason:
            'Gender or age uncertain',
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      await db.collection('verification_requests')
        .doc(verifiedUid)
        .set({
          aiStatus: 'manual_review',
          aiGender: gender,
          aiAge: age,
          aiProvider: 'facepp',
          aiCheckedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      return res.json({
        success: false,
        status: 'manual_review',
        gender,
        age,
      });
    }

    // ─── APPROVED
    await db.collection('users')
      .doc(verifiedUid)
      .set({
        verificationStatus: 'approved',
        isVerified: true,
        verifiedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

    await db.collection('verification_requests')
      .doc(verifiedUid)
      .set({
        aiStatus: 'approved',
        aiGender: gender,
        aiAge: age,
        aiProvider: 'facepp',
        approvedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

    return res.json({
      success: true,
      status: 'approved',
      gender,
      age,
    });

  } catch (error) {

    console.error(
      'AI verification error:',
      error,
    );

    return res.status(500).json({
      success: false,
      status: 'error',
      error: 'AI verification failed',
    });
  }
});

// ─── 404 Handler ──────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} pa egziste.`,
  });
});

// ─── Start Server ─────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000;

  app.listen(PORT, '0.0.0.0', () => {
    console.log(
      `🌸 Lesbie Chat Backend running on port ${PORT}`,
    );
  });
}

module.exports = app;