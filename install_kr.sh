#!/bin/sh

# ==============================================================================
#      System-wide oh-my-zsh installer
# ==============================================================================

# --- 1. Root 권한 확인 ---
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ 이 스크립트는 반드시 root 권한으로 실행해야 합니다." >&2
  exit 1
fi

# --- 2. 지원하는 리눅스 배포판 확인 ---
if [ -f /etc/os-release ]; then
  # /etc/os-release 파일을 읽어 ID 변수를 가져옵니다.
  . /etc/os-release
else
  echo "❌ OS 버전을 확인할 수 없습니다. (/etc/os-release 파일 없음)" >&2
  exit 1
fi

case "$ID" in
  ubuntu|debian|rocky)
    # 지원하는 OS일 경우 계속 진행
    echo "✅ 지원하는 운영체제($ID) 입니다."
    ;;
  *)
    # 지원하지 않는 OS일 경우 메시지 출력 후 종료
    echo "❌ 이 스크립트는 Ubuntu, Debian, Rocky Linux만 지원합니다." >&2
    echo "   (감지된 OS: $ID)" >&2
    exit 1
    ;;
esac


# --- 설치 시작 ---
# 이미 설치되었다면 실행하지 않음
if [ -d /oh-my-zsh ]; then
  echo "ℹ️ Oh My Zsh가 이미 /oh-my-zsh에 설치되어 있습니다. 스크립트를 종료합니다."
  exit 0
fi

# Github에서 파일을 받아올 주소
GH="https://raw.githubusercontent.com/KREONET/ohmyzsh/refs/heads/main/"

# 패키지 매니저를 확인하여 git 설치
echo "Git 설치를 시작합니다..."
if [ -x "$(which apt-get)" ]; then
  apt-get update && apt-get -y install git wget
elif [ -x "$(which dnf)" ]; then
  dnf -y install git wget
else
  echo "❌ apt-get 또는 dnf 패키지 매니저를 찾을 수 없습니다." >&2
  exit 1
fi

# oh-my-zsh 및 플러그인 설치
echo "Oh My Zsh와 플러그인을 복제합니다..."
git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh /oh-my-zsh
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting /oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# 사용자 정의 설정 파일 다운로드
echo "사용자 정의 테마와 zshrc 템플릿을 다운로드합니다..."
wget ${GH}/custom/zshrc.zsh-template -O /oh-my-zsh/custom/zshrc.zsh-template
wget ${GH}/custom/themes/dallas.zsh-theme -O /oh-my-zsh/custom/themes/dallas.zsh-theme

# --- 3. 사용자 설정 적용 전 확인 ---
echo "" # 줄바꿈
read -p "❓ 모든 사용자에게 zsh 설정을 적용하고 기본 쉘을 zsh로 변경하시겠습니까? [y/N] " confirm
echo "" # 줄바꿈

case "$confirm" in
  [yY]*)
    echo "사용자 설정을 적용합니다..."
    if [ -d /home ]; then
      for H in /home/*; do
        if [ -d "$H" ]; then # /home 아래에 있는 것이 디렉터리인지 확인
          U="$(basename "$H")"
          echo "  -> $U 사용자에게 .zshrc 파일 적용"
          cp /oh-my-zsh/custom/zshrc.zsh-template "$H/.zshrc"
          chown "$U:$U" "$H/.zshrc"
        fi
      done
    fi

    echo "기본 쉘을 zsh로 변경합니다..."
    # /bin/bash를 /bin/zsh로 정확하게 변경하여 더 안전하게 만듦
    sed -i 's|/bin/bash|/bin/zsh|g' /etc/passwd
    sed -i 's#SHELL=.*#SHELL=/bin/zsh#g' /etc/default/useradd;
    echo "✅ 모든 작업이 완료되었습니다."
    ;;
  *)
    echo "ℹ️ 사용자가 취소했습니다. Oh My Zsh 설치만 완료되었으며, 사용자 설정은 적용되지 않았습니다."
    exit 0
    ;;
esac
