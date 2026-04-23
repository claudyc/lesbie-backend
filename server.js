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
  res.json({ success: true, message: '🌸 Lesbie Chat Backend ap mache!' });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ success: true, ok: true });
});

// Kreye Subscription $20/mwa
app.post('/create-subscription', async (req, res) => {
  try {
    const { userId, email, paymentMethodId } = req.body;

    if (!userId || !email || !paymentMethodId) {
      return res.status(400).json({ error: 'Tout champ yo obligatwa' });
    }

    let customer;
    const existingCustomers = await stripe.customers.list({
      email,
      limit: 1,
    });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
    } else {
      customer = await stripe.customers.create({
        email,
        metadata: { user_id: userId },
      });
    }

    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });

    await stripe.customers.update(customer.id, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: process.env.STRIPE_PRICE_ID }],
      metadata: { user_id: userId },
      expand: ['latest_invoice.payment_intent'],
    });

    await db.collection('users').doc(userId).update({
      isPremium: true,
      premiumSince: admin.firestore.FieldValue.serverTimestamp(),
      stripeCustomerId: customer.id,
      stripeSubscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
    });

    res.json({
      success: true,
      subscriptionId: subscription.id,
      status: subscription.status,
    });
  } catch (error) {
    console.error('Subscription error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Anile Subscription
app.post('/cancel-subscription', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId obligatwa' });

    const userDoc = await db.collection('users').doc(userId).get();
    const subscriptionId = userDoc.data()?.stripeSubscriptionId;

    if (!subscriptionId) {
      return res.status(400).json({ error: 'Pa gen abònman aktif' });
    }

    await stripe.subscriptions.cancel(subscriptionId);

    await db.collection('users').doc(userId).update({
      isPremium: false,
      subscriptionStatus: 'canceled',
      premiumCanceledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true, message: 'Abònman anile' });
  } catch (error) {
    console.error('Cancel error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Kreye VerificationSession pou Stripe Identity
app.post('/create-verification-session', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId obligatwa' });

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

// Kreye PaymentIntent pou Boost pwofil
app.post('/create-boost-payment', async (req, res) => {
  try {
    const { userId, boostType } = req.body;
    const prices = { '1h': 99, '6h': 299, '24h': 499 };
    const amount = prices[boostType];
    if (!amount) return res.status(400).json({ error: 'Tip boost pa valid' });

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

// Kreye Agora Token pou Video Chat
app.post('/generate-agora-token', async (req, res) => {
  try {
    const { channelName, uid } = req.body;

    if (!channelName || !uid) {
      return res.status(400).json({
        error: 'channelName ak uid obligatwa',
      });
    }

    const { RtcTokenBuilder, RtcRole } = require('agora-token');

    const appId = process.env.AGORA_APP_ID;
    const appCertificate = process.env.AGORA_APP_CERTIFICATE;
    const role = RtcRole.PUBLISHER;
    const expirationTimeInSeconds = 3600;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs =
        currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      role,
      privilegeExpiredTs,
      privilegeExpiredTs,
    );

    res.json({ token, appId });
  } catch (error) {
    console.error('Agora token error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Webhook Stripe
app.post('/webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body, sig,
        process.env.STRIPE_WEBHOOK_SECRET || ''
      );
    } catch (err) {
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    switch (event.type) {
      case 'customer.subscription.deleted':
      case 'customer.subscription.updated':
        const subscription = event.data.object;
        const subUserId = subscription.metadata.user_id;
        if (subUserId) {
          await db.collection('users').doc(subUserId).update({
            isPremium: subscription.status === 'active',
            subscriptionStatus: subscription.status,
          });
        }
        break;

      case 'identity.verification_session.verified':
        const verifiedUserId =
            event.data.object.metadata.user_id;
        if (verifiedUserId) {
          await db.collection('users').doc(verifiedUserId).update({
            isVerified: true,
            verifiedAt:
                admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        break;

      case 'identity.verification_session.requires_input':
        const failedUserId =
            event.data.object.metadata.user_id;
        if (failedUserId) {
          await db.collection('users').doc(failedUserId).update({
            isVerified: false,
            verificationFailedAt:
                admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        break;

      default:
        console.log(`Event: ${event.type}`);
    }

    res.json({ received: true });
  }
);

// Route 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route sa pa egziste.',
  });
});

if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🌸 Lesbie Chat Backend running on port ${PORT}`);
  });
}

module.exports = app;