/**
 * map.js — MapLibre GL map initialization
 *
 * Data is served from data/map.pmtiles (built by `make all`).
 * The PMTiles file contains three vector layers:
 *   land      — Natural Earth land polygons (background fill)
 *   countries — Country boundaries
 *   states    — Admin-1 boundaries (US states carry a census_region attribute)
 */

import { REGION_COLOR_EXPR, REGION_COLORS } from "./regions.js";

// ── PMTiles protocol registration ─────────────────────────────────
const protocol = new pmtiles.Protocol();
maplibregl.addProtocol("pmtiles", protocol.tile.bind(protocol));

// ── Map configuration ─────────────────────────────────────────────
const MAP_CONFIG = {
  tilesUrl: "pmtiles://data/map.pmtiles",
  center: [-98.5, 39.5],   // geographic center of the contiguous US
  zoom: 3.5,
  minZoom: 1.5,
  maxZoom: 10,
};

// ── Style definition ──────────────────────────────────────────────
function buildStyle(tilesUrl) {
  return {
    version: 8,
    sources: {
      composite: {
        type: "vector",
        url: tilesUrl,
      },
    },
    layers: [
      // Ocean background
      {
        id: "background",
        type: "background",
        paint: { "background-color": "#c4d6e3" },
      },

      // Land mass (no-data fill so country shapes are always visible)
      {
        id: "land",
        type: "fill",
        source: "composite",
        "source-layer": "land",
        paint: { "fill-color": "#edeae0" },
      },

      // Non-US admin-1 regions (Canada provinces, Mexico states, etc.)
      {
        id: "states-other",
        type: "fill",
        source: "composite",
        "source-layer": "states",
        filter: ["!=", ["get", "iso_a2"], "US"],
        paint: {
          "fill-color": "#d6d2c4",
          "fill-opacity": 0.8,
        },
      },

      // US states — colored by Census region
      {
        id: "states-us",
        type: "fill",
        source: "composite",
        "source-layer": "states",
        filter: ["==", ["get", "iso_a2"], "US"],
        paint: {
          "fill-color": REGION_COLOR_EXPR,
          "fill-opacity": 0.82,
        },
      },

      // Hover highlight (toggled via setFilter)
      {
        id: "states-hover",
        type: "fill",
        source: "composite",
        "source-layer": "states",
        paint: { "fill-color": "rgba(255, 255, 255, 0.28)" },
        filter: ["literal", false],
      },

      // Admin-1 borders (thin white lines)
      {
        id: "states-border",
        type: "line",
        source: "composite",
        "source-layer": "states",
        paint: {
          "line-color": "rgba(255, 255, 255, 0.75)",
          "line-width": [
            "interpolate", ["linear"], ["zoom"],
            2, 0.4,
            8, 1.2,
          ],
        },
      },

      // Country borders (slightly darker, drawn above state lines)
      {
        id: "countries-border",
        type: "line",
        source: "composite",
        "source-layer": "countries",
        paint: {
          "line-color": "rgba(50, 50, 50, 0.35)",
          "line-width": [
            "interpolate", ["linear"], ["zoom"],
            2, 0.8,
            8, 2.0,
          ],
        },
      },
    ],
  };
}

// ── Map initialization ────────────────────────────────────────────
const map = new maplibregl.Map({
  container: "map",
  style: buildStyle(MAP_CONFIG.tilesUrl),
  center: MAP_CONFIG.center,
  zoom: MAP_CONFIG.zoom,
  minZoom: MAP_CONFIG.minZoom,
  maxZoom: MAP_CONFIG.maxZoom,
});

map.addControl(new maplibregl.NavigationControl(), "top-right");

// ── Tooltip ───────────────────────────────────────────────────────
const tooltip = document.getElementById("tooltip");

function showTooltip(point, props) {
  const region = props.census_region || "—";
  tooltip.innerHTML = `<strong>${props.name ?? props.postal}</strong><br/>${region}`;
  tooltip.style.left = `${point.x + 14}px`;
  tooltip.style.top  = `${point.y - 36}px`;
  tooltip.style.display = "block";
}

function hideTooltip() {
  tooltip.style.display = "none";
}

// ── Hover interactions ────────────────────────────────────────────
let hoveredPostal = null;

map.on("load", () => {
  map.on("mousemove", "states-us", (e) => {
    if (!e.features.length) return;
    map.getCanvas().style.cursor = "pointer";

    const postal = e.features[0].properties.postal;
    if (postal !== hoveredPostal) {
      hoveredPostal = postal;
      map.setFilter("states-hover", ["==", ["get", "postal"], postal]);
    }
    showTooltip(e.point, e.features[0].properties);
  });

  map.on("mouseleave", "states-us", () => {
    map.getCanvas().style.cursor = "";
    hoveredPostal = null;
    map.setFilter("states-hover", ["literal", false]);
    hideTooltip();
  });

  // Tile load error feedback
  map.on("error", (e) => {
    if (e.error?.message?.includes("map.pmtiles")) {
      document.getElementById("load-error").style.display = "block";
    }
  });
});

// ── Legend ────────────────────────────────────────────────────────
function buildLegend() {
  const legend = document.getElementById("legend");
  Object.entries(REGION_COLORS).forEach(([name, color]) => {
    const item = document.createElement("div");
    item.className = "legend-item";
    item.innerHTML = `
      <span class="swatch" style="background:${color}"></span>
      <span>${name}</span>`;
    legend.appendChild(item);
  });
}

buildLegend();
