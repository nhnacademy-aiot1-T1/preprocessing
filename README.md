#### R을 사용하여 전처리 작업을 합니다.
---
2개의 설정 파일 (yml)을 요구합니다. influx db 관련 설정 파일이 없을 경우, 동작하지 않습니다.

파일의 이름 및 확장자는 config.yaml, influx.yaml입니다.

추후 추가 및 변동될 여지 또한 존재합니다.

- influx.yaml: token, url, org를 필요로 합니다.
- config.yaml: bucket, gateway, measurement, channel, field를 필요로 합니다. channel는 list item입니다.

yaml 파일의 형태는 다음과 같습니다.

influx:
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

config:
```yaml
default:
 settings:
  bucket: "bucket"
  gateway: "gateway"
  measurement: "measurement"
  channel:
   - "channel1"
   - "channel2"
  field: "field"
```
