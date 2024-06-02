if (!requireNamespace("config", quietly = TRUE)) {
  install.packages("config")
}
if (!requireNamespace("influxdbclient", quietly = TRUE)) {
  install.packages("influxdbclient")
}
if (!requireNamespace("zoo", quietly = TRUE)) {
  install.packages("zoo")
}

library(influxdbclient)

config_file <- "config.yaml"
influx_config <- "influx.yaml"

if (file.exists(config_file)) {
  config <- config::get(file = config_file)
  
  bucket <- config$settings$bucket
  gateway <- config$settings$gateway
  measurement <- config$settings$measurement
  channels <- config$settings$channel
  motors <- config$settings$motor
  field <- config$settings$field
  
} else {
  bucket <- "data"
  gateway <- "gateway1"
  measurement <- "measurement"
  channels <-c("DemoDevice")
  motorss <-c("DemoMotor")
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


interpolate_na <- function(x) {

  x[is.infinite(x)] <- NA
  
  na_index <- which(is.na(x))
  if (length(na_index) > 0) {
    for (i in na_index) {
      if (i > 1 && i < length(x)) {
        if (!is.na(x[i-1]) && !is.na(x[i+1])) {
          x[i] <- (x[i-1] + x[i+1]) / 2
        } else if (!is.na(x[i-1])) {
          x[i] <- x[i-1]
        } else if (!is.na(x[i+1])) {
          x[i] <- x[i+1]
        }
      } else if (i == 1) {
        x[i] <- x[i+1]
      } else if (i == length(x)) {
        x[i] <- x[i-1]
      }
    }
  }
  return(x)
}

for (motor in motors) {
  for (channel in channels) {

    cat("----------start----------\n")  

    fluxQuery <- sprintf(
      'from(bucket: "%s") |> range(start: -1m) |> filter(fn: (r) => r._measurement == "%s") |> filter(fn: (r) => r.channel == "%s") |> filter(fn: (r) => r.gateway == "%s") |> filter(fn: (r) => r._field == "%s") |> filter(fn: (r) => r.motor == "%s")', 
      bucket, measurement, channel, gateway, field, motor)
  
    data <- client$query(fluxQuery)
    cat("client에 read query 완료.\n")  
    if (!is.null(data)) {
    
      data_df <- data.frame(data) ## 들어오는 데이터를 data frame으로 변환.
      cat("data value 개수",length(data_df$X_value),"\n")

      data_df$X_value[is.infinite(data_df$X_value)] <- NA
      data_df$X_value <- interpolate_na(data_df$X_value)

      cat("Inf 값 NA로 변환\n")

      data_df$X_value <- zoo::na.locf(data_df$X_value, na.rm = FALSE, fromLast = FALSE)
      data_df$X_value <- zoo::na.locf(data_df$X_value, na.rm = FALSE, fromLast = TRUE)

      cat("남아 있을 na값 재검토 및 처리\n")

      normalized_vector <- max(data_df$X_value, na.rm = TRUE)

      if(normalized_vector != 0){    
        normalized_data <- scale(data_df$X_value, center = FALSE, scale= normalized_vector)
      } else {
        normalized_data <- data_df$X_value
      }

      cat("표준화 진행 완료\n")

      result_df <- data.frame(
        time = data_df$time,
        value = normalized_data,
        channel = data_df$channel,
        gateway = data_df$gateway,
        motor = data_df$motor,
        measurement = data_df$X_measurement
      )

      cat("결과 프레임 생성\n")
    
      output_client$write(result_df, bucket = "ai", precision = "ms", measurementCol = "measurement", tagCols = c("channel", "gateway", "motor"), fieldCols = c("value"), timeCol = "time")
      cat("output_client write query 완료.\n")
      cat("channel is:", channel, "\n")

      cat("----------end-----------\n")
    }
  }
}
