"""
process.py — Natural Earth shapefile → enriched GeoJSON

Usage:
    python process.py <layer> <input.zip> <output.geojson>

Layers:
    states    admin-1 boundaries; US states get a census_region attribute
    land      physical land polygons (geometry only)
    countries admin-0 country boundaries (minimal attributes)
"""

import sys
import zipfile
import tempfile
from pathlib import Path

import geopandas as gpd

# ── Census Bureau regions ─────────────────────────────────────────
CENSUS_REGIONS = {
    "Northeast": ["CT", "ME", "MA", "NH", "RI", "VT", "NJ", "NY", "PA"],
    "Midwest":   ["IL", "IN", "MI", "OH", "WI", "IA", "KS", "MN", "MO", "NE", "ND", "SD"],
    "South":     ["AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS",
                  "NC", "OK", "SC", "TN", "TX", "VA", "WV"],
    "West":      ["AK", "AZ", "CA", "CO", "HI", "ID", "MT", "NV", "NM",
                  "OR", "UT", "WA", "WY"],
}

POSTAL_TO_REGION: dict[str, str] = {
    postal: region
    for region, postals in CENSUS_REGIONS.items()
    for postal in postals
}

# ─────────────────────────────────────────────────────────────────

def load_zip(zip_path: Path) -> gpd.GeoDataFrame:
    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(tmp)
        shp_files = list(Path(tmp).rglob("*.shp"))
        if not shp_files:
            raise FileNotFoundError(f"No .shp found in {zip_path}")
        return gpd.read_file(shp_files[0])


def process_states(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    gdf = gdf.copy()
    gdf["census_region"] = gdf.apply(
        lambda row: POSTAL_TO_REGION.get(row.get("postal", ""), "")
        if row.get("iso_a2") == "US" else "",
        axis=1,
    )
    keep = [c for c in ["geometry", "name", "postal", "iso_a2"] if c in gdf.columns]
    return gdf[keep + ["census_region"]]


def process_land(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    return gdf[["geometry"]]


def process_countries(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    keep = [c for c in ["geometry", "ADMIN", "ISO_A2", "NAME"] if c in gdf.columns]
    return gdf[keep]


PROCESSORS = {
    "states":    process_states,
    "land":      process_land,
    "countries": process_countries,
}


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    layer, zip_path, out_path = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])

    if layer not in PROCESSORS:
        print(f"Unknown layer '{layer}'. Choose from: {list(PROCESSORS)}")
        sys.exit(1)

    print(f"Loading {zip_path} ...")
    gdf = load_zip(zip_path)
    gdf = PROCESSORS[layer](gdf)

    # Ensure WGS-84
    if gdf.crs and gdf.crs.to_epsg() != 4326:
        gdf = gdf.to_crs(epsg=4326)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    gdf.to_file(out_path, driver="GeoJSON")
    print(f"Wrote {len(gdf)} features → {out_path}")


if __name__ == "__main__":
    main()
