import mapboxgl from "mapbox-gl"
import MapboxGeocoder from "@mapbox/mapbox-gl-geocoder"

function initGeocoder({ inputId, containerId, placeholder }) {
  const token = document.querySelector('meta[name="mapbox-token"]')?.content
  if (!token) return

  const input = document.getElementById(inputId)
  const container = document.getElementById(containerId)
  if (!input || !container) return

  mapboxgl.accessToken = token
  container.innerHTML = ""

  const geocoder = new MapboxGeocoder({
    accessToken: token,
    mapboxgl,
    marker: false,
    flyTo: false,
    placeholder: placeholder || "Search address",
    types: "address,poi,place,locality,neighborhood"
  })

  geocoder.addTo(container)

  geocoder.on("result", (event) => {
    const placeName = event?.result?.place_name || ""
    input.value = placeName
    input.dispatchEvent(new Event("input", { bubbles: true }))
  })

  geocoder.on("clear", () => {
    input.value = ""
    input.dispatchEvent(new Event("input", { bubbles: true }))
  })
}

function initAll() {
  initGeocoder({ inputId: "task_start", containerId: "start-geocoder", placeholder: "Search pickup" })
  initGeocoder({ inputId: "task_target", containerId: "target-geocoder", placeholder: "Search drop-off" })
}

document.addEventListener("turbo:load", initAll)
