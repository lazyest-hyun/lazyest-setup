# Lazyest Setup

한국어 사용자와 개발자를 위한 **일회성 macOS 초기 설정 앱**입니다. `Lazyest Setup.app`에서 필요한 항목만 선택해 적용하고, 초기 설정이 끝나면 Setup 앱을 삭제할 수 있습니다.

- Current version: [`1.2.1`](VERSION)
- macOS 13+
- Apple Silicon Mac에서 검증하며 Intel Mac은 해당 기기에서 소스 빌드
- [The Unlicense](UNLICENSE)

## 설치와 배포 상태

2026년 9월 7일 기준 **1.2.1 Apple Silicon DMG**를 로컬에서 준비하고 앱·DMG의 Developer ID 서명, Apple 공증, 스테이플과 Gatekeeper 검증을 완료했습니다. 이 새 버전은 아직 공개 GitHub Release에 게시하지 않았습니다. 공개 페이지에 남아 있는 PKG는 이전 버전이며 이번 DMG와 다릅니다.

공개되면 DMG와 SHA-256 체크섬을 확인하고 앱을 `/Applications`로 옮겨 실행합니다. 지금 소스에서 설치하려면 다음 안내를 따릅니다.

## AI Agent 설치

소스 저장소 접근 권한이 있는 계정에서 사용자가 **Setup 설치**를 명시적으로 요청했다면, 추가 조사나 dry-run 없이 아래 한 명령으로 설치하고 실행합니다.

```sh
(workdir="$(mktemp -d)" && trap 'rm -rf "$workdir"' EXIT && git clone --depth 1 --quiet https://github.com/lazyest-hyun/lazyest-setup.git "$workdir" && "$workdir/bootstrap.sh" install-setup && open "/Applications/Lazyest Setup.app")
```

- 최신 소스만 얕게 받아 현재 Mac에서 빌드하고 `/Applications/Lazyest Setup.app`에 설치한 뒤 임시 소스와 빌드 산출물을 제거합니다.
- Flow 설치, Homebrew 설치, 앱 설치, macOS 설정 적용은 수행하지 않습니다. Setup UI에서 사용자가 고른 항목만 나중에 변경됩니다.
- Setup 소스를 직접 빌드할 때 Swift 도구 모음이 없으면 `xcode-select --install`로 macOS 설치 확인을 열고, 사용자가 승인한 뒤 위 명령을 다시 실행합니다.

![Lazyest Setup 앱 설치 화면](docs/images/setup-install.png)

실제 앱의 화면 코드로 만든 예시입니다. 설치 상태는 예시이며 개인 계정이나 경로를 포함하지 않습니다.

## Flow는 별도 프로젝트입니다

상시 실행 메뉴 막대 앱은 [Lazyest Flow](https://github.com/lazyest-hyun/lazyest-flow)에서 독립적으로 개발하고 설치합니다.

Setup의 `Flow` 탭에서 Flow가 없을 때 버튼을 누르면 [최신 GitHub Release 페이지](https://github.com/lazyest-hyun/lazyest-flow/releases/latest)를 엽니다. 공개된 배포본의 형식과 버전을 확인해 설치합니다. 새 DMG는 아직 공개되지 않았으며 공개 페이지의 기존 PKG는 이전 버전입니다. Setup 저장소에는 Flow 소스나 런타임 설정을 포함하지 않습니다.

## Setup 기능

### 앱 설치

- Homebrew
- Chrome, Arc, Aside, Raycast
- Codex, Claude, Cursor, VS Code, Zed, Docker Desktop, iTerm2
- Teams, Slack
- Gureum 입력기, Karabiner-Elements, LinearMouse, Amphetamine

### 텍스트와 키보드

- Gureum 두벌식 입력 소스 등록
- Gureum 입력 소스 등록에는 Apple Command Line Tools의 Swift가 필요하며, 전체 Xcode는 필요하지 않습니다.
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
git clone https://github.com/lazyest-hyun/lazyest-setup.git
cd lazyest-setup

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

Flow 릴리즈 페이지:

```sh
./bootstrap.sh install-flow [--dry-run]
./bootstrap.sh uninstall-flow [--dry-run]
```

## 배포 패키지 준비

현재 배포 경로는 아래 `DMG 패키지`입니다. 별도 PKG가 필요한 경우에만 Developer ID Application, Developer ID Installer 인증서와 Apple 공증 프로필을 모두 준비한 Mac에서 아래 선택 절차를 사용합니다. 값 자체는 저장소에 기록하지 않고 셸 환경으로 전달합니다.

```sh
LAZYEST_CODESIGN_IDENTITY="Developer ID Application: ..." \
LAZYEST_INSTALLER_IDENTITY="Developer ID Installer: ..." \
LAZYEST_TEAM_ID="..." \
LAZYEST_NOTARY_PROFILE="lazyest-notary" \
./scripts/package-macos-release.sh --preflight

LAZYEST_CODESIGN_IDENTITY="Developer ID Application: ..." \
LAZYEST_INSTALLER_IDENTITY="Developer ID Installer: ..." \
LAZYEST_TEAM_ID="..." \
LAZYEST_NOTARY_PROFILE="lazyest-notary" \
./scripts/package-macos-release.sh
```

완료되면 `dist/Lazyest-Setup-<version>-macOS.pkg`와 SHA-256 파일이 생깁니다. 이 명령은 GitHub Release나 App Store 등록을 만들지 않습니다.

macOS 설정 명령 전체는 `./bootstrap.sh help`에서 확인할 수 있습니다. 실제 적용 전에는 대응하는 `--dry-run`을 먼저 사용할 수 있습니다.

## 안전한 기본값

- Setup을 열면 상태만 읽고 설정을 강제로 적용하지 않습니다.
- 기본 앱 단축키나 상시 실행 기능을 추가하지 않습니다.
- 비밀번호, 토큰, Keychain 값과 전체 환경변수를 저장하거나 출력하지 않습니다.
- `sudo` 또는 생체 인증이 필요하면 사용자가 직접 확인합니다.
- Flow 릴리즈 페이지를 여는 동작은 기존 `~/Library/Application Support/Lazyest Flow/` 설정을 변경하지 않습니다.

## Flow 릴리즈 방식

Flow 저장소와 최신 릴리즈 페이지는 [`config/bootstrap.conf`](config/bootstrap.conf)의 `FLOW_REPOSITORY`, `FLOW_RELEASE_PAGE_URL`에서 확인할 수 있습니다. Setup은 릴리즈 파일을 자동 설치하거나 빌드하지 않고, GitHub의 최신 릴리즈 페이지를 엽니다. 새 DMG가 게시되면 해당 버전의 앱을 `/Applications`로 옮겨 실행합니다. 공개 페이지의 기존 PKG는 이전 버전입니다.

Flow 릴리즈를 내려받아 사용하는 데는 사용자 Mac에 Swift나 전체 Xcode를 설치할 필요가 없습니다. Setup 소스 빌드와 Dock, 입력 소스, 입력 단축키, Karabiner 설정에는 Apple Command Line Tools가 필요합니다. 도구가 없으면 설정을 바꾸기 전에 안내하며 설치를 강제로 시작하지 않습니다.

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

## 처음 사용하는 순서

1. 소스 설치는 `./bootstrap.sh install-setup` 한 번이면 현재 소스를 빌드하고 설치합니다. 소스 경로에 공백이 있어도 동작합니다.
2. 앱을 열고 `간편 설정 시작`에서 필요한 설정을 선택합니다. 앱 설치는 `설치` 탭에서 별도로 선택합니다.
3. 항목과 버튼 위에 마우스를 올리면 변경 범위와 선행 조건을 확인할 수 있습니다.
4. 입력기 등록 후 macOS가 로그아웃을 요구하면 작업을 저장한 뒤 진행합니다.

새 앱 식별자는 `com.lazyest.setup`입니다. 예전 식별자와 설정 이름은 기존 언어 설정, 복구용 백업, 이전 앱 제거에만 사용합니다. 새 백업은 `~/Library/Application Support/Lazyest Setup/Backups`에 보관하며 기존 복구 백업이 있으면 계속 사용합니다. 자세한 내용은 [개인정보 처리](PRIVACY.md)를 참고하세요.

문서 화면은 설정이나 설치 작업 없이 다시 만들 수 있습니다.

```sh
./bootstrap.sh build-setup
setup/LazyestSetup/.build/release/LazyestSetup --export-preview docs/images/setup-install.png
```

XCTest 검증은 Xcode의 개발 도구 경로를 해당 명령에만 지정합니다. 앱 빌드에는 전체 Xcode가 필요하지 않습니다.

```sh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" \
  swift test --disable-sandbox --package-path setup/LazyestSetup
```

### DMG 패키지

현재 배포 형식은 DMG입니다. Developer ID Application으로 서명한 앱을 준비하면 Installer 인증서 없이 패키징할 수 있습니다. 이 명령은 앱과 DMG를 각각 Apple에 공증하고 Gatekeeper 검사를 통과한 파일 및 상대 경로 SHA-256 체크섬을 남깁니다. 공개 업로드는 수행하지 않습니다.

```sh
LAZYEST_CODESIGN_IDENTITY="Developer ID Application: <publisher> (<team-id>)" \
LAZYEST_NOTARY_PROFILE="lazyest-notary" \
scripts/package-dmg.sh "$PWD/dist/Lazyest Setup.app" "$PWD/dist/Lazyest-Setup-macOS.dmg"
```

DMG를 열고 앱을 Applications로 옮긴 뒤 `/Applications`의 앱을 실행합니다. 현재 검증한 1.2.1 DMG는 Apple Silicon용입니다. 다른 CPU용 배포를 추가하려면 해당 빌드와 실행을 별도로 검증해야 합니다. 소스 변경 후에는 앱을 다시 빌드하고 서명해야 합니다.
