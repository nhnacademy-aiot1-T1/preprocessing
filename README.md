# Preprocessing api

전처리를 담당하는 repository입니다.
스케줄링을 사용하여 일정 시간마다 influxdb에서 데이터를 가져와, 전처리를 하고 influxdb에 값을 저장합니다.

influxClient를 사용하였습니다.


## 사용 기술
전처리: R
사용한 packages: config, influxdbclient


## 주요 기능
- yml 파일을 읽어 setting을 합니다.
- 어디에 연결할 것인지(config.yaml), 연결할 때 필요한 것(token, etc) (influx.yaml)를 필요로 합니다.
- 데이터는 -Inf, Inf값에 대한 처리, 정규화, 결측치에 대한 처리를 합니다.
- influxdb 관련 설정(config.yaml) 파일이 없을 경우, 동작하지 않습니다.


### config.yaml
```yaml
default:
 settings:
  bucket: "bucket"
  gateway: "gateway"
  measurement: "measurement"
  channel:
   - "channel1"
   - "channel2"
  motor:
   - "DemoMotor1"
   - "DemoMotor2"
  field: "field"
```

### influx.yaml
```yaml
default:
 settings: 
  token: "12345"
  url: "localhost:8086"
  org: "org"

 output:
  token: "token"
  url: "localhost:8086"
  org: "org"
```


## 담당자
임찬휘
