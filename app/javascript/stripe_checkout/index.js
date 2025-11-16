import { loadStripe } from "@stripe/stripe-js"

document.addEventListener("turbo:load", initializeCheckout)
document.addEventListener("DOMContentLoaded", initializeCheckout)

async function initializeCheckout() {
  const form = document.querySelector("form[data-controller='checkout']") || document.querySelector("form[data-stripe-checkout]")
  const publishableKey = document.querySelector("[data-stripe-publishable-key]")?.dataset?.stripePublishableKey || document.querySelector("meta[name='stripe-publishable-key']")?.content

  if (!form || !publishableKey) return

  if (form.dataset.stripeInitialized === "true") return
  form.dataset.stripeInitialized = "true"

  const stripe = await loadStripe(publishableKey)
  if (!stripe) return

  const hiddenInput = document.createElement("input")
  hiddenInput.type = "hidden"
  hiddenInput.name = "stripe_checkout"
  hiddenInput.value = "1"
  form.appendChild(hiddenInput)

  form.addEventListener("submit", () => {
    form.querySelector("button[type='submit']")?.setAttribute("disabled", "disabled")
  })
}
