# ─────────────────────────────────────────────────────────────────
#  basic-web-map — Makefile
#
#  Targets
#    make check       verify required tools are installed
#    make download    fetch Natural Earth source zips
#    make process     convert shapefiles → enriched GeoJSON
#    make tiles       GeoJSON → map.pmtiles via tippecanoe
#    make build       assemble dist/ for deployment
#    make serve       local HTTP server on dist/ (port 8080)
#    make all         check → download → process → tiles → build
#    make clean       remove dist/
#    make distclean   remove dist/ + processed/tiles data
#    make clobber     remove everything including source downloads
# ─────────────────────────────────────────────────────────────────

# ── Tools ────────────────────────────────────────────────────────
PYTHON     := python3
TIPPECANOE := tippecanoe
CURL       := curl -fsSL

# ── Natural Earth source URLs ─────────────────────────────────────
NE_BASE      := https://naturalearth.s3.amazonaws.com
NE_LAND      := $(NE_BASE)/50m_physical/ne_50m_land.zip
NE_STATES    := $(NE_BASE)/50m_cultural/ne_50m_admin_1_states_provinces.zip
NE_COUNTRIES := $(NE_BASE)/50m_cultural/ne_50m_admin_0_countries.zip

# ── Directories ───────────────────────────────────────────────────
DATA_SRC  := data/sources
DATA_PROC := data/processed
DATA_TILES := data/tiles
SRC       := src
DIST      := dist

# ── Source zips ───────────────────────────────────────────────────
LAND_ZIP      := $(DATA_SRC)/ne_50m_land.zip
STATES_ZIP    := $(DATA_SRC)/ne_50m_admin_1_states_provinces.zip
COUNTRIES_ZIP := $(DATA_SRC)/ne_50m_admin_0_countries.zip

# ── Processed GeoJSON ─────────────────────────────────────────────
LAND_GEOJSON      := $(DATA_PROC)/land.geojson
STATES_GEOJSON    := $(DATA_PROC)/states.geojson
COUNTRIES_GEOJSON := $(DATA_PROC)/countries.geojson

# ── Output tiles ─────────────────────────────────────────────────
MAP_TILES := $(DATA_TILES)/map.pmtiles

# ─────────────────────────────────────────────────────────────────

.PHONY: all check download process tiles build serve clean distclean clobber

all: check download process tiles build

# ── Dependency check ──────────────────────────────────────────────
check:
	@command -v $(PYTHON) >/dev/null 2>&1 \
		|| (echo "ERROR: python3 not found"; exit 1)
	@$(PYTHON) -c "import geopandas" 2>/dev/null \
		|| (echo "ERROR: geopandas missing — run: pip install -r requirements.txt"; exit 1)
	@command -v $(TIPPECANOE) >/dev/null 2>&1 \
		|| (echo "ERROR: tippecanoe not found\n  macOS:  brew install tippecanoe\n  Ubuntu: sudo apt install tippecanoe\n  Build:  https://github.com/felt/tippecanoe"; exit 1)
	@command -v $(CURL) >/dev/null 2>&1 \
		|| (echo "ERROR: curl not found"; exit 1)
	@echo "All dependencies satisfied."

# ── Download ──────────────────────────────────────────────────────
download: $(LAND_ZIP) $(STATES_ZIP) $(COUNTRIES_ZIP)

$(LAND_ZIP):
	@mkdir -p $(DATA_SRC)
	$(CURL) $(NE_LAND) -o $@
	@echo "Downloaded: $@"

$(STATES_ZIP):
	@mkdir -p $(DATA_SRC)
	$(CURL) $(NE_STATES) -o $@
	@echo "Downloaded: $@"

$(COUNTRIES_ZIP):
	@mkdir -p $(DATA_SRC)
	$(CURL) $(NE_COUNTRIES) -o $@
	@echo "Downloaded: $@"

# ── Process ───────────────────────────────────────────────────────
process: $(LAND_GEOJSON) $(STATES_GEOJSON) $(COUNTRIES_GEOJSON)

$(STATES_GEOJSON): $(STATES_ZIP) scripts/process.py
	@mkdir -p $(DATA_PROC)
	$(PYTHON) scripts/process.py states $< $@

$(LAND_GEOJSON): $(LAND_ZIP) scripts/process.py
	@mkdir -p $(DATA_PROC)
	$(PYTHON) scripts/process.py land $< $@

$(COUNTRIES_GEOJSON): $(COUNTRIES_ZIP) scripts/process.py
	@mkdir -p $(DATA_PROC)
	$(PYTHON) scripts/process.py countries $< $@

# ── Tiles ─────────────────────────────────────────────────────────
tiles: $(MAP_TILES)

$(MAP_TILES): $(LAND_GEOJSON) $(STATES_GEOJSON) $(COUNTRIES_GEOJSON)
	@mkdir -p $(DATA_TILES)
	$(TIPPECANOE) \
		--output=$@ \
		--force \
		--minimum-zoom=0 \
		--maximum-zoom=8 \
		--generate-ids \
		--no-tile-size-limit \
		--named-layer=land:$(LAND_GEOJSON) \
		--named-layer=countries:$(COUNTRIES_GEOJSON) \
		--named-layer=states:$(STATES_GEOJSON)
	@echo "Built: $@"

# ── Build ─────────────────────────────────────────────────────────
build: $(MAP_TILES)
	@mkdir -p $(DIST)/data
	cp -r $(SRC)/. $(DIST)/
	cp $(MAP_TILES) $(DIST)/data/
	@echo "Built dist/ — ready for deployment"

# ── Serve ─────────────────────────────────────────────────────────
serve:
	$(PYTHON) scripts/serve.py 8080 $(DIST)

# ── Cleanup ───────────────────────────────────────────────────────
clean:
	rm -rf $(DIST)

distclean: clean
	rm -rf $(DATA_PROC) $(DATA_TILES)

clobber: distclean
	rm -rf $(DATA_SRC)
