import Stripe from "stripe";
import { supabaseAdmin } from "@/lib/supabaseAdmin";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Stripe requires the raw request body to verify the webhook signature,
// so this route reads text() rather than json().
export async function POST(req) {
  const body = await req.text();
  const signature = req.headers.get("stripe-signature");

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return Response.json({ error: "Invalid signature" }, { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const { course_id, user_id } = session.metadata;

    const { error } = await supabaseAdmin.from("enrollments").upsert(
      {
        user_id,
        course_id,
        payment_status: "paid",
        stripe_session_id: session.id,
      },
      { onConflict: "user_id,course_id" }
    );

    if (error) console.error("Failed to record enrollment:", error);
  }

  return Response.json({ received: true });
}
