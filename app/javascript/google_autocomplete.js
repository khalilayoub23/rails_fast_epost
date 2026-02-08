// Dynamically loads Google Maps JS API (Places library) and attaches autocomplete to task start/target inputs.
(function () {
  const KEY_META_NAME = "google-maps-key"
  let scriptLoading = false
  let scriptLoaded = false
  const callbacks = []

  function loadScript(key) {
    if (scriptLoaded) return Promise.resolve()
    if (scriptLoading) return new Promise((resolve) => callbacks.push(resolve))

    scriptLoading = true
    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}&libraries=places&callback=__googleMapsReady`
      script.async = true
      script.onerror = () => reject(new Error("Failed to load Google Maps JS"))
      window.__googleMapsReady = () => {
        scriptLoaded = true
        scriptLoading = false
        resolve()
        callbacks.splice(0).forEach((cb) => cb())
      }
      document.head.appendChild(script)
    })
  }

  function initAutocomplete() {
    const key = document.querySelector(`meta[name="${KEY_META_NAME}"]`)?.content
    if (!key) return

    loadScript(key)
      .then(() => {
        const startInput = document.getElementById("task_start")
        const targetInput = document.getElementById("task_target")
        const pickupAddressInput = document.getElementById("task_pickup_address")
        const homeAddressInput = document.getElementById("user_home_address")
        const officeAddressInput = document.getElementById("user_office_address")
        const customerAddressInput = document.getElementById("customer_address")
        if (startInput) attachAutocomplete(startInput, startInput.dataset.autocompletePlaceholder || startInput.placeholder || "Search pickup")
        if (targetInput) attachAutocomplete(targetInput, targetInput.dataset.autocompletePlaceholder || targetInput.placeholder || "Search drop-off")
        if (pickupAddressInput) attachAutocomplete(pickupAddressInput, pickupAddressInput.dataset.autocompletePlaceholder || pickupAddressInput.placeholder || "Search pickup address")
        if (homeAddressInput) attachAutocomplete(homeAddressInput, homeAddressInput.dataset.autocompletePlaceholder || homeAddressInput.placeholder || "Search home address")
        if (officeAddressInput) attachAutocomplete(officeAddressInput, officeAddressInput.dataset.autocompletePlaceholder || officeAddressInput.placeholder || "Search office address")
        if (customerAddressInput) attachAutocomplete(customerAddressInput, customerAddressInput.dataset.autocompletePlaceholder || customerAddressInput.placeholder || "Search address")
      })
      .catch((err) => {
        console.warn("Google Maps autocomplete init failed", err)
      })
  }

  function attachAutocomplete(input, placeholder) {
    if (!window.google || !google.maps?.places) return
    if (placeholder) input.placeholder = placeholder
    const autocomplete = new google.maps.places.Autocomplete(input, {
      fields: ["formatted_address", "geometry"],
      types: ["address"],
      componentRestrictions: {},
    })
    autocomplete.addListener("place_changed", () => {
      const place = autocomplete.getPlace()
      if (place?.formatted_address) {
        input.value = place.formatted_address
        input.dispatchEvent(new Event("input", { bubbles: true }))
      }
    })
  }

  document.addEventListener("turbo:load", initAutocomplete)
})()
