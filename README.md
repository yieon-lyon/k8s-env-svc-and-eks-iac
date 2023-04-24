
## ENV Manager Applcation

---
### kubernetes secret 업데이트 서비스

#### app code: [./application/practice](./application/practice)
#### app yaml: [./infra/applications/practice/dev](./infra/applications/practice/dev)

Express 기반의 SSR 사용
- reason
    - 가장 기본이 되는 configmap이나 secret을 비교적 간단하게 업데이트 할 수 있는 기능을 모델로 선정하고 MVP 개발
    - express + next 형태의 간단한 모듈셋으로 backend와 frontend를 구현할 수 있다.
    - 코드의 일관성을 위해 동일한 언어 사용 : typescript
- use case
  1. 화면 진입 후 SecretList에 보이는 업데이트 하고자 하는 시크릿의 secretName을 클릭
  2. 아래 노출된 `get data` 버튼 클릭
  2-1. 조회된 secret의 data를 확인
  3. 변경하고자 하는 data 값 변경 (key, value)
  4. `secret update` 버튼 클릭
  5. secret data 업데이트 완료

---

## IaC 플랫폼

EKS
- 배포하고자 하는 환경변수 관리 서비스를 위해 kubernetes를 사용한 서비스 구현을 목적으로 eks를 사용하였으며 간단하게 구축이 가능하고 kubernetes의 기능들을 활용하고자 선정


---
## crew sharing use-guide doc

어플리케이션 로그 확인 및 재시작
- kubectl 명령어를 기본으로 합니다.
  - 어플리케이션 log 조회
    - `kubectl logs [-f optional] [application-name]`
  - 어플리케이션 재시작
    - `kubectl restart deployment`
- k9s 사용을 지향합니다. kubernetes를 직관적으로 볼 수 있는 대시보드내에서 편리하게 조작이 가능합니다.

IaC terraform plan
- plan.sh 스크립트 만들어두었습니다.
  - `./plan.sh`로 상태 체크하시면 됩니다.

---

### 이외 운영에 필요한 정보 [docs/README.md](./docs/README.md)