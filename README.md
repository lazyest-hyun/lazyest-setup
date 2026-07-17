# Lazyest Setup

한국어 사용자와 개발자를 위한 **일회성 macOS 초기 설정 앱**입니다. `Lazyest Setup.app`에서 필요한 항목만 선택해 적용하고, 초기 설정이 끝나면 Setup 앱을 삭제할 수 있습니다.

- Current version: [`0.4.0`](VERSION)
- macOS 13+
- Apple Silicon Mac에서 테스트
- [The Unlicense](UNLICENSE)

## AI Agent 설치

사용자가 **Setup 설치**를 명시적으로 요청했다면, 추가 조사나 dry-run 없이 아래 한 명령으로 설치하고 실행합니다.

```sh
(workdir="$(mktemp -d)" && trap 'rm -rf "$workdir"' EXIT && git clone --depth 1 --quiet https://github.com/hyunn515/lazyest-setup.git "$workdir" && "$workdir/bootstrap.sh" install-setup && open "/Applications/Lazyest Setup.app")
```

- 최신 소스만 얕게 받아 현재 Mac에서 빌드하고 `/Applications/Lazyest Setup.app`에 설치한 뒤 임시 소스와 빌드 산출물을 제거합니다.
- Flow 설치, Homebrew 설치, 앱 설치, macOS 설정 적용은 수행하지 않습니다. Setup UI에서 사용자가 고른 항목만 나중에 변경됩니다.
- Swift 도구 모음이 없으면 `xcode-select --install`로 macOS 설치 확인을 열고, 사용자가 승인한 뒤 위 명령을 다시 실행합니다.

![Lazyest Setup 앱 설치 화면](docs/images/setup-install.png)

## Flow는 별도 프로젝트입니다

상시 실행 메뉴 막대 앱은 [Lazyest Flow](https://github.com/hyunn515/lazyest-flow)에서 독립적으로 개발하고 설치합니다.

Setup의 `Flow` 탭에서 설치 버튼을 누르면 별도 Flow 프로젝트를 내려받아 `/Applications/Lazyest Flow.app`으로 설치합니다. Setup 저장소에는 Flow 소스나 런타임 설정을 포함하지 않습니다.

## Setup 기능

### 앱 설치

- Homebrew
- Chrome, Arc, Aside, Raycast
- Codex, Claude, Cursor, VS Code, Zed, Docker Desktop, iTerm2
- Teams, Slack
- Gureum 입력기, Karabiner-Elements, LinearMouse, Amphetamine

### 텍스트와 키보드

- Gureum 두벌식 입력 소스 등록
- Karabiner Complex Modification으로 오른쪽 Command를 `F18`로 변경
- 이전 입력 소스 단축키 비활성화 및 다음 입력 소스를 `F18`로 설정
- 키 반복, 길게 눌러 악센트, 기능 키, Globe/Fn 키 설정
- 맞춤법 자동 수정, 스페이스 두 번 마침표, 인라인 자동 완성 설정

### 데스크톱과 Dock

- 배경화면 클릭으로 데스크톱 보기 방지
- macOS 내장 검은색 배경화면 적용
- Dock 자동 숨김
- 체크리스트로 Dock 기본 앱 구성

각 항목은 현재 상태를 다시 읽어 `설치`, `열기`, `적용`, `초기화`처럼 가능한 다음 행동을 표시합니다.

## 수동 설치

```sh
git clone https://github.com/hyunn515/lazyest-setup.git
cd mac-bootstrap

./bootstrap.sh audit
./bootstrap.sh plan
./bootstrap.sh install-plan
./bootstrap.sh build-setup
./bootstrap.sh install-setup

open "/Applications/Lazyest Setup.app"
```

앱 설치만으로 시스템 설정을 자동 적용하지 않습니다. Setup UI에서 사용자가 누른 항목만 변경합니다.

## 주요 명령어

읽기 전용:

```sh
./bootstrap.sh version
./bootstrap.sh audit
./bootstrap.sh plan
./bootstrap.sh install-plan
```

Setup 앱:

```sh
./bootstrap.sh build-setup [--dry-run]
./bootstrap.sh install-setup [--dry-run]
./bootstrap.sh uninstall-setup [--dry-run]
```

별도 Flow 연결:

```sh
./bootstrap.sh install-flow [--dry-run]
./bootstrap.sh uninstall-flow [--dry-run]
```

macOS 설정 명령 전체는 `./bootstrap.sh help`에서 확인할 수 있습니다. 실제 적용 전에는 대응하는 `--dry-run`을 먼저 사용할 수 있습니다.

## 안전한 기본값

- Setup을 열면 상태만 읽고 설정을 강제로 적용하지 않습니다.
- 기본 앱 단축키나 상시 실행 기능을 추가하지 않습니다.
- 비밀번호, 토큰, Keychain 값과 전체 환경변수를 저장하거나 출력하지 않습니다.
- `sudo` 또는 생체 인증이 필요하면 사용자가 직접 확인합니다.
- Flow 설치는 기존 `~/Library/Application Support/Lazyest Flow/` 설정을 덮어쓰지 않습니다.

## Flow 설치 방식

Flow 저장소와 설치할 리비전은 [`config/bootstrap.conf`](config/bootstrap.conf)의 `FLOW_REPOSITORY`, `FLOW_REF`에서 변경할 수 있습니다. Setup은 해당 소스를 임시 폴더에 내려받고 Flow 저장소의 설치 명령을 실행한 뒤 임시 파일을 삭제합니다.

현재는 GitHub Release 바이너리 대신 소스 빌드를 사용하므로 Swift 도구 모음이 필요합니다.

## 검증

```sh
bash -n bootstrap.sh scripts/*.sh
./bootstrap.sh audit
./bootstrap.sh plan
./bootstrap.sh install-plan
./bootstrap.sh build-setup --dry-run
./bootstrap.sh install-flow --dry-run
swift build --package-path setup/LazyestSetup -c release --product LazyestSetup
```
