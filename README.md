# basic-web-map

Interactive choropleth map of US states colored by [Census Bureau region](https://www2.census.gov/geo/pdfs/maps-data/maps/reference/us_regdiv.pdf). Built entirely from open data — no API key, no tile server.

## Stack

| Layer | Tool |
|---|---|
| Rendering | [MapLibre GL JS](https://maplibre.org/) v4 |
| Tiles | [PMTiles](https://protomaps.com/docs/pmtiles) (single-file tile archive, no server) |
| Base data | [Natural Earth](https://www.naturalearthdata.com/) 1:50m (public domain) |
| Tile builder | [tippecanoe](https://github.com/felt/tippecanoe) |
| Data processing | Python + [geopandas](https://geopandas.org/) |
| Deployment | GitHub Pages via GitHub Actions |

## Quick start

```bash
# 1. Install Python dependencies
pip install -r requirements.txt

# 2. Build everything (download → process → tiles → dist/)
make all

# 3. Serve locally
make serve
# → http://localhost:8080
```

> **Note:** `make serve` uses `scripts/serve.py` rather than Python's built-in server because PMTiles requires HTTP range request support.

## Makefile targets

| Target | Description |
|---|---|
| `make all` | Full build from scratch |
| `make check` | Verify required tools are installed |
| `make download` | Fetch Natural Earth source zips |
| `make process` | Convert shapefiles → enriched GeoJSON |
| `make tiles` | Build `map.pmtiles` via tippecanoe |
| `make build` | Assemble `dist/` for deployment |
| `make serve` | Local HTTP server on port 8080 |
| `make clean` | Remove `dist/` |
| `make distclean` | Remove `dist/` + processed/tile data |
| `make clobber` | Remove all generated files including downloads |

## Project structure

```
basic-web-map/
├── Makefile
├── requirements.txt
├── .github/workflows/pages.yml   # auto-build + deploy to GitHub Pages
├── scripts/
│   ├── process.py                # Natural Earth zip → enriched GeoJSON
│   ├── serve.py                  # HTTP server with range request support
│   └── check-deps.sh
└── src/
    ├── index.html
    ├── js/
    │   ├── map.js                # MapLibre init, layers, hover, tooltip
    │   └── regions.js            # Census region definitions and colors
    └── css/style.css
```

Generated directories (`data/sources/`, `data/processed/`, `data/tiles/`, `dist/`) are gitignored and reproduced by `make all`.

## Dependencies

- **Python 3.9+** with `geopandas` and `fiona` (`pip install -r requirements.txt`)
- **tippecanoe** — [installation instructions](https://github.com/felt/tippecanoe#installation)
  - macOS: `brew install tippecanoe`
  - Ubuntu: `sudo apt install tippecanoe`
- **curl**

## Customizing

### Change region colors

Edit `src/js/regions.js`:

```js
export const REGION_COLORS = {
  Northeast: "#c96d54",
  Midwest:   "#4d8ab5",
  South:     "#62a35a",
  West:      "#c49a36",
};
```

Then `make build && make serve`.

### Reassign states to regions

Edit `CENSUS_REGIONS` in both `src/js/regions.js` (for client-side coloring) and `scripts/process.py` (for the GeoJSON attribute). Then rebuild with `make process tiles build`.

### Add a new data layer

1. Add a download target in `Makefile` and a processor in `scripts/process.py`
2. Add a `--named-layer` argument to the tippecanoe command in `Makefile`
3. Add the layer definition to `buildStyle()` in `src/js/map.js`

## Deploying to GitHub Pages

1. Push this repo to GitHub
2. Go to **Settings → Pages → Source** and select **GitHub Actions**
3. Push any commit to `main` — the workflow builds and deploys automatically

## Data sources

- [Natural Earth](https://www.naturalearthdata.com/) — public domain
- [US Census Bureau regions and divisions](https://www2.census.gov/geo/pdfs/maps-data/maps/reference/us_regdiv.pdf)
