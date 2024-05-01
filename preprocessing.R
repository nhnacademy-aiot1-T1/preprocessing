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
  factory <- config$settings$factory
  domain <- config$settings$domain
  gateway <- config$settings$gateway
  measurement <- config$settings$measurement
  channels <- config$settings$channel
  field <- config$settings$field
  
} else {
  bucket <- "data"
  factory <- "factory"
  domain <- "aiotone"
  gateway <- "gateway1"
  measurement <- "measurement"
  channels <-c("DemoDevice")
  field <- "value"
  
}

if (file.exists(influx_config)) {
  influx_config_data <- config::get(file = influx_config)
  
  if (!is.null(influx_config_data$settings$token) && !is.null(influx_config_data$settings$url) && !is.null(influx_config_data$settings$org) ){
  token <- influx_config_data$settings$token
  url <- influx_config_data$settings$url
  org <- influx_config_data$settings$org
  
  output_token <- influx_config_data$output$token
  output_url <- influx_config_data$output$url
  output_org <- influx_config_data$output$org
  
  } 
  else {
    stop("필요한 설정 값이 influx_config 파일에 없습니다.")
  } 
} else {
    stop("influx_config 파일을 찾을 수 없습니다.")
}

client <- InfluxDBClient$new(url = url, token = token, org = org)
output_client <- InfluxDBClient$new(url = output_url, token = output_token, org = output_org)

df_result <- data.frame()

for (channel in channels) {

  fluxQuery <- sprintf(
    'from(bucket: "%s") |> range(start: -5m) |> filter(fn: (r) => r._measurement == "%s") |> filter(fn: (r) => r.channel == "%s") |> filter(fn: (r) => r.domain == "%s") |> filter(fn: (r) => r._field == "%s")', 
    bucket, measurement, channel, domain, field)
  
  data <- client$query(fluxQuery)
  
  if (!is.null(data)) {
    
      data_df <- data.frame(data) ## 들어오는 데이터를 data frame으로 변환.
      normalized_vector <- max(data_df$X_value, na.rm = TRUE)
      
      normalized_data <- scale(data_df$X_value, center = FALSE, scale= normalized_vector)
      
      result_df <- data.frame(
        time = data_df$time,
        value = normalized_data,
        domain = data_df$domain,
        channel = data_df$channel,
        factory = data_df$factory,
        gateway = data_df$gateway,
        measurement = data_df$X_measurement
      )
      
      output_client$write(result_df, bucket = "preprocessing", precision = "ms", measurementCol = "measurement", tagCols = c("domain", "channel","factory", "gateway"), fieldCols = c("normalized_data"), timeCol = "time")
  }
}
