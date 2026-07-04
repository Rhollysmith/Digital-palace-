"use client";
import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

export default function CheckoutPage({ params }) {
  const { courseId } = params;
  const [course, setCourse] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    supabase.from("courses").select("*").eq("id", courseId).single()
      .then(({ data }) => setCourse(data));
  }, [courseId]);

  async function startCheckout() {
    setLoading(true);
    setError("");
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      window.location.href = "/login";
      return;
    }
    const res = await fetch("/api/checkout", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ courseId }),
    });
    const data = await res.json();
    if (data.url) window.location.href = data.url;
    else {
      setError(data.error || "Something went wrong starting checkout.");
      setLoading(false);
    }
  }

  if (!course) return <main className="max-w-lg mx-auto px-6 py-20">Loading…</main>;

  return (
    <main className="max-w-lg mx-auto px-6 py-16">
      <h1 className="font-display text-2xl mb-6">Checkout</h1>
      <div className="card mb-6">
        <div className="flex justify-between">
          <span>{course.title}</span>
          <span className="font-medium">${course.price}</span>
        </div>
      </div>
      {error && <p className="text-sm text-red-600 mb-4">{error}</p>}
      <button onClick={startCheckout} disabled={loading} className="btn-primary w-full">
        {loading ? "Redirecting to secure payment…" : "Pay with card"}
      </button>
      <p className="text-xs text-ink/50 mt-4 text-center">
        Payments are processed securely by Stripe. We never see your card details.
      </p>
    </main>
  );
}
