require("dotenv").config();

const express = require("express");
const cors = require("cors");
const Stripe = require("stripe");

const app = express();

app.use(cors());
app.use(express.json());

// Verifye si Stripe key la egziste
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey) : null;

// Route tès
app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Lesbie Chat backend ap mache",
  });
});

// Health check
app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    ok: true,
  });
});

// Kreye payment intent
app.post("/create-payment-intent", async (req, res) => {
  try {
    if (!stripe) {
      return res.status(500).json({
        success: false,
        message: "STRIPE_SECRET_KEY pa configure sou server la.",
      });
    }

    const { amount, currency = "usd" } = req.body;

    if (!amount || typeof amount !== "number" || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Montan an pa valid.",
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    return res.status(200).json({
      success: true,
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error("Stripe error:", error.message);

    return res.status(500).json({
      success: false,
      message: error.message || "Erè pandan kreyasyon peman an.",
    });
  }
});

// Si route pa egziste
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route sa pa egziste.",
  });
});

const PORT = process.env.PORT || 3000;

// Enpòtan pou Railway
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});