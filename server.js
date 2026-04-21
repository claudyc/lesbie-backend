require('dotenv').config();
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Test route
app.get('/', (req, res) => {
  res.json({ status: 'Lesbie Chat Backend ap travay! 🌸' });
});

// Kreye VerificationSession pou Stripe Identity
app.post('/create-verification-session', async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'userId obligatwa' });
    }

    const verificationSession = await stripe.identity
      .verificationSessions.create({
        type: 'document',
        metadata: {
          user_id: userId,
        },
        options: {
          document: {
            require_matching_selfie: true,
          },
        },
        return_url: 'https://lesbie-chat.com/verified',
      });

    res.json({
      client_secret: verificationSession.client_secret,
      id: verificationSession.id,
      url: verificationSession.url,
    });
  } catch (error) {
    console.error('Stripe error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Webhook pou resevwa rezilta Stripe
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
        console.log(`✅ User ${verifiedUserId} verifye!`);

        // TODO: Mete ajou Firestore via Firebase Admin SDK
        break;

      case 'identity.verification_session.requires_input':
        const failedSession = event.data.object;
        const failedUserId = failedSession.metadata.user_id;
        const reason = failedSession.last_error?.reason;
        console.log(
          `❌ Verifikasyon rate pou ${failedUserId}: ${reason}`
        );
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

    const prices = {
      '1h': 99,    // $0.99
      '6h': 299,   // $2.99
      '24h': 499,  // $4.99
    };

    const amount = prices[boostType];
    if (!amount) {
      return res.status(400).json({ error: 'Tip boost pa valid' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: 'usd',
      metadata: {
        user_id: userId,
        boost_type: boostType,
      },
    });

    res.json({
      client_secret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Payment error:', error);
    res.status(400).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🌸 Lesbie Chat Backend running on port ${PORT}`);
});