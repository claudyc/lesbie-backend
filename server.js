require('dotenv').config();
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');
const admin = require('firebase-admin');

// Inisyalize Firebase Admin
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

app.use(cors());
app.use(express.json());

// Route tès
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🌸 Lesbie Chat Backend ap mache!',
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ success: true, ok: true });
});

// Kreye VerificationSession pou Stripe Identity
app.post('/create-verification-session', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'userId obligatwa' });
    }

    const session = await stripe.identity.verificationSessions.create({
      type: 'document',
      metadata: { user_id: userId },
      options: { document: { require_matching_selfie: true } },
      return_url: 'https://lesbie-chat.com/verified',
    });

    res.json({
      client_secret: session.client_secret,
      id: session.id,
      url: session.url,
    });
  } catch (error) {
    console.error('Verification error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Webhook Stripe — resevwa rezilta verifikasyon
app.post(
  '/webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET || ''
      );
    } catch (err) {
      console.error('Webhook error:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    switch (event.type) {
      case 'identity.verification_session.verified':
        const verifiedSession = event.data.object;
        const verifiedUserId = verifiedSession.metadata.user_id;

        try {
          // Mete ajou Firestore — isVerified = true
          await db.collection('users').doc(verifiedUserId).update({
            isVerified: true,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`✅ User ${verifiedUserId} verifye nan Firestore!`);
        } catch (e) {
          console.error('Firestore update error:', e);
        }
        break;

      case 'identity.verification_session.requires_input':
        const failedSession = event.data.object;
        const failedUserId = failedSession.metadata.user_id;
        const reason = failedSession.last_error?.reason;

        try {
          // Mete ajou Firestore — verifikasyon rate
          await db.collection('users').doc(failedUserId).update({
            isVerified: false,
            verificationFailedReason: reason || 'unknown',
            verificationFailedAt:
                admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`❌ Verifikasyon rate pou ${failedUserId}: ${reason}`);
        } catch (e) {
          console.error('Firestore update error:', e);
        }
        break;

      default:
        console.log(`Event: ${event.type}`);
    }

    res.json({ received: true });
  }
);

// Kreye PaymentIntent pou Boost pwofil
app.post('/create-boost-payment', async (req, res) => {
  try {
    const { userId, boostType } = req.body;
    const prices = { '1h': 99, '6h': 299, '24h': 499 };
    const amount = prices[boostType];

    if (!amount) {
      return res.status(400).json({ error: 'Tip boost pa valid' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      metadata: { user_id: userId, boost_type: boostType },
    });

    res.json({ client_secret: paymentIntent.client_secret });
  } catch (error) {
    console.error('Payment error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Route 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route sa pa egziste.',
  });
});

// Pou lokal sèlman
if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🌸 Lesbie Chat Backend running on port ${PORT}`);
  });
}

module.exports = app;