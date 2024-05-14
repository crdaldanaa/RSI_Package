## Cargar ROI
library(sf)
library(rsi)
library(svDialogs)

## Definir Workspace
workspace <- dlgInput(message = "Ingrese la ruta de trabajo: ")$res

setwd(workspace)


roi <- dlgInput(message = "Ingrese la ruta del shapefile: ")$res
roi <- sf::read_sf(roi)
crs <- dlgInput(message = "Ingrese proyección a definir (Unidad metros): ")$res
crs_num <- as.numeric(crs)

## CRS 9377 (CTM12 Proyección Oficial Colombia)
roi <- sf::st_transform(roi, crs = crs_num)

sf::st_geometry(roi) |> plot()

## Elegir forma de ejecución
future::plan("sequential")
progressr::handlers(global = TRUE)

init_year <- dlgInput(message = "Ingrese el año de inicio del mosaico: ")$res
init_year <- as.numeric(init_year)

end_year <- dlgInput(message = "Ingrese el año final del mosaico: ")$res
end_year <- as.numeric(end_year)

downloaded_years <- vapply(
  init_year:end_year,
  function(year) {
    image <- get_landsat_imagery(
      aoi = roi,
      start_date = glue::glue("{year}-01-01"),
      end_date = glue::glue("{year}-12-31"),
      mask_function = \(r) landsat_mask_function(r, include = "both"),
      composite_function = "median",
      output_filename = tempfile(fileext = ".tif")
    )
    indices <- calculate_indices(
      image,
      filter_bands(bands = names(terra::rast(image))),
      glue::glue("land_indices_{year}.tif")
    )
    dem <- get_dem(roi)
    progressr::handlers(global = TRUE)
    combined_layers <- stack_rasters(
      c(image, indices, dem),
      glue::glue("Landsat_{year}.vrt")
    )
  },
  character(1)
)
