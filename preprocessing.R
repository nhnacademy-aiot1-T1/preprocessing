if (!requireNamespace("config", quietly = TRUE)) {
  install.packages("config")
}
if (!requireNamespace("influxdbclient", quietly = TRUE)) {
  install.packages("influxdbclient")
}

library(influxdbclient)

config_file <- "config.yaml"
influx_config <- "influx.yaml"

if (file.exists(config_file)) {
  config <- config::get(file = config_file)
  
  bucket <- config$settings$bucket
  domain <- config$settings$domain
  company <- config$settings$company
  sector <- config$settings$sector
  motor <- config$settings$motor
  sensors <- strsplit(config$settings$sensors, ",")[[1]]
  
} else {
  bucket <- "data"
  domain <- "aiotone.com"
  company <- "demo"
  sector <- "demo"
  motor <- "demo"
  sensors <- c("vibration1", "vibration2", "vibration3","temperature","power_consumption","pressure","noise")
}

if (file.exists(influx_config)) {
  influx_config_data <- config::get(file = influx_config)
  
  if (!is.null(influx_config_data$settings$token) && !is.null(influx_config_data$settings$url) && !is.null(influx_config_data$settings$org) ){
    token <- influx_config_data$settings$token
    url <- influx_config_data$settings$url
    org <- influx_config_data$settings$org
  } 
  else {
    stop("필요한 설정 값이 influx_config 파일에 없습니다.")
  } 
} else {
  stop("influx_config 파일을 찾을 수 없습니다.")
}
client <- InfluxDBClient$new(url = url, token = token, org = org)

df_result <- data.frame()

for (sensor in sensors) {
  
  fluxQuery <- sprintf(
    'from(bucket: "%s") |> range(start: -5m) |> filter(fn: (r) => r.domain == "%s") |> filter(fn: (r) => r.company == "%s") |> filter(fn: (r) => r.sector == "%s") |> filter(fn: (r) => r.motor == "%s") |> filter(fn: (r) => r._field == "%s")', 
    bucket, domain, company, sector, motor, sensor)
  
  data <- client$query(fluxQuery)
  if (!is.null(data)) {
    
    if(sensor != "temperature") {
      normalized_data <- scale(data$value, center = FALSE, scale= max(data$value, na.rm = TRUe))
      data_ts <- ts(normalized_data, start = 1, frequency = 1)
      df_data_ts <- data.frame(as.vector(data_ts))
      names(df_data_ts) <- sensor
    } else {
      
    }
    if (ncol(df_result) == 0) {
      df_result <- df_data_ts
    } else {
      df_result <- cbind(df_result, df_data_ts)
    }
  }
}

write.csv(df_result, "result.csv")

