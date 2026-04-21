require('dotenv').config();
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ success: true, message: '🌸 Lesbie Chat Backend ap mache!' });
});

app.get('/health', (req, res) => {
  res.json({ success: true, ok: true });
});

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

    res.json({ client_secret: session.client_secret, id: session.id, url: session.url });
  } catch (error) {
    console.error('Verification error:', error);
    res.status(400).json({ error: error.message });
  }
});

app.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET || '');
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'identity.verification_session.verified':
      console.log(`✅ User ${event.data.object.metadata.user_id} verifye!`);
      break;
    case 'identity.verification_session.requires_input':
      console.log(`❌ Rate pou ${event.data.object.metadata.user_id}`);
      break;
    default:
      console.log(`Event: ${event.type}`);
  }

  res.json({ received: true });
});

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

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route sa pa egziste.' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🌸 Lesbie Chat Backend running on port ${PORT}`);
});
