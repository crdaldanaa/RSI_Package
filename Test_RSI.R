## Cargar ROI
library(sf)
library(rsi)
library(svDialogs)

## Definir Workspace
workspace <- dlgInput(message="Ingrese la ruta de trabajo: ")$res
setwd(workspace)

# Cargar Feature Class
roi <- dlgInput(message="Ingrese la ruta del shapefile: ")$res
roi <- sf::read_sf(roi)

# Mostrar Poligono(s) Seleccionados
sf::st_geometry(roi) |> plot()

## Ver atributos de las imagenes landsat
landsat_band_mapping
sentinel2_band_mapping

## Obtener Sistema de Coordenadas
crs_shapefile <- sf::st_crs(roi)

## Transformar a Sistema de Coordenadas Metriczs (CTM12 en este caso)

projected_roi <- sf::st_transform(roi, crs = 9377)
crs_shapefile_prj <- st_crs(projected_roi)


## Elegir forma de ejecución
future::plan("sequential")
progressr::handlers(global = TRUE)

## Crear mosaico de medianas
landsat_2020 <- get_landsat_imagery(
  aoi = projected_roi,
  start_date = "2017-01-01",
  end_date = "2017-12-30",
  mask_function = \(r) landsat_mask_function(r, include = "both"),
  composite_function = "median"
)

## Obtener todos los indices espectrales probables
future::plan("sequential")
progressr::handlers(global = TRUE)
landsat_2020_indices <- calculate_indices(
  landsat_2020,
  filter_bands(bands = names(terra::rast(landsat_2020))),
  "landsat_2015_indices.tif" 
)

## Obtener un dem del ROI
roi_dem <- get_dem(projected_roi)

## Compilar todos los archivos tif en uno solo
future::plan("sequential")
progressr::handlers(global = TRUE)
combined_layers <- stack_rasters(
  c(landsat_2020, landsat_2020_indices, roi_dem),
  "Imagen_2013_SF.vrt"
)

terra::plot(terra::rast(landsat_2020))
terra::plot(terra::rast(landsat_2020_indices))
terra::plot(terra::rast(combined_layers))