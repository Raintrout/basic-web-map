/**
 * regions.js — US Census Bureau region definitions and color palette
 *
 * To change region colors, edit REGION_COLORS.
 * To reassign states, edit CENSUS_REGIONS — then re-run `make process tiles build`.
 */

export const REGION_COLORS = {
  Northeast: "#c96d54",
  Midwest:   "#4d8ab5",
  South:     "#62a35a",
  West:      "#c49a36",
};

export const CENSUS_REGIONS = {
  Northeast: ["CT", "ME", "MA", "NH", "RI", "VT", "NJ", "NY", "PA"],
  Midwest:   ["IL", "IN", "MI", "OH", "WI", "IA", "KS", "MN", "MO", "NE", "ND", "SD"],
  South:     ["AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS",
              "NC", "OK", "SC", "TN", "TX", "VA", "WV"],
  West:      ["AK", "AZ", "CA", "CO", "HI", "ID", "MT", "NV", "NM",
              "OR", "UT", "WA", "WY"],
};

// MapLibre GL match expression: census_region property → fill color
export const REGION_COLOR_EXPR = [
  "match", ["get", "census_region"],
  "Northeast", REGION_COLORS.Northeast,
  "Midwest",   REGION_COLORS.Midwest,
  "South",     REGION_COLORS.South,
  "West",      REGION_COLORS.West,
  "#b8b4a8",  // unassigned US territories / non-US admin-1 units
];
