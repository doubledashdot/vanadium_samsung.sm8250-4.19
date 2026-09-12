#!/usr/bin/env bash
# good luck, you will need it :)
SECONDS=0;G=$'\033[0;32m';R=$'\033[0;31m';Y=$'\033[1;33m';B=$'\033[0;34m';C=$'\033[0;36m';N=$'\033[0m'
A=(bloomxq c1q c2q f2q gts7l gts7lwifi gts7xl gts7xlwifi r8q x1q y2q z3q);Z=(stock ksu ksu+permissive)
Q="$(pwd)";U=https://github.com/notkernel-oss/AnyKernel3;T="$Q/tc/clang";O="$Q/out";H="$O/arch/arm64/boot";D="$H/dts/vendor/qcom";L="$O/build.log";E=65;P=;V=0;X=0;TTY=0;[[ -t 1 ]]&&TTY=1
p(){ echo "==============================================";echo "$1";shift;for x;do echo "$x";done;echo "=============================================="; }
v(){ local x=$1;shift;for y;do [[ $x == "$y" ]]&&return 0;done;return 1; }
l(){ printf '%s\n' "$*" >>"$L"; }
h(){ ((TTY))&&printf '\033[?25l'; }
s(){ ((TTY))&&printf '\033[?25h'; }
k(){ local p=$1;[[ -z $p ]]&&return 0;kill -TERM -- "-$p" 2>/dev/null||:;kill -TERM "$p" 2>/dev/null||:;sleep .25;kill -KILL -- "-$p" 2>/dev/null||:;kill -KILL "$p" 2>/dev/null||:; }
d(){ ((TTY))||return 0;((V))&&printf '\033[%dA' "$((E+1))";local a=() n i;mapfile -t a < <(tail -n "$E" "$L" 2>/dev/null);n=${#a[@]};for((i=0;i<E;i++));do printf '\r\033[K';((i<n))&&printf '%s' "${a[i]}";printf '\n';done;printf '\r\033[K%b%s [%s]%b' "$C" "$1" "$2" "$N";V=1; }
c(){ ((TTY))||return 0;((V))||return 0;printf '\033[%dA' "$((E+1))";for((i=0;i<E+1;i++));do printf '\r\033[K';((i<E))&&printf '\n';done;printf '\033[%dA' "$((E+1))";V=0; }
q(){ trap - INT TERM;X=1;if [[ -n $P ]];then c;s;printf '%b\n' "${Y}Stopping build...${N}";k "$P";wait "$P" 2>/dev/null||:;P=;fi;c;s;l "";l "==============================================";l "BUILD CANCELLED BY USER";l "==============================================";printf '\n%b\n' "${R}✗ Build cancelled by user.${N}";printf '%b\n' "${Y}Log: $L${N}";exit 130; }
trap q INT TERM
r(){ local m=$1;shift;((X))&&return 130;l "";l ">>> $m";l ">>> Command: $*";l "";local w='-\|/' j=0 z;setsid "$@" >>"$L" 2>&1 & P=$!;h;d "$m" "${w:j:1}";while kill -0 "$P" 2>/dev/null;do sleep .15;j=$(( (j+1)%4 ));d "$m" "${w:j:1}";done;wait "$P";z=$?;P=;c;s;if [[ $z -ne 0 ]];then printf '%b\n' "${R}✗${N} $m";l "";l "!!! FAILED: $m";l "!!! Exit code: $z";return "$z";fi;printf '%b\n' "${G}✓${N} $m";l ">>> Completed: $m";return 0; }
p "Which project do you want to build?" "${A[@]}";read -r -p " - Enter your choice: " m;m=$(printf '%s' "$m"|tr '[:upper:]' '[:lower:]');v "$m" "${A[@]}"||{ echo "Invalid model choice! Exiting.";exit 1; }
p "Do you want to build with ksu/permissive?" "${Z[@]}";read -r -p " - Enter your choice: " a;a=$(printf '%s' "$a"|tr '[:upper:]' '[:lower:]');v "$a" "${Z[@]}"||{ echo "Invalid build add-on! Exiting.";exit 1; };echo "=============================================="
M=$m;export PROJECT_NAME="$M";PC="vendor/samsung/${M}.config";[[ -z ${PLATFORM_VERSION:-} ]]&&export PLATFORM_VERSION=11;PD=vendor/kona-perf_defconfig;CD=vendor/samsung/kona-sec-common.config;W="$(date '+%Y%m%d').zip"
case $a in
stock) W="not-$W";EX="vendor/not/localversion.config";;
ksu) W="not-ksu-$W";EX="vendor/not/ksu.config vendor/not/localversion.config";;
ksu+permissive) W="not-ksu-permissive-$W";EX="vendor/not/ksu.config vendor/not/localversion.config vendor/not/permissive.config";;
esac
DF="$PD $CD $PC $EX"
if git rev-parse --verify HEAD >/dev/null 2>&1;then F=$(git rev-parse HEAD);S=$(git rev-parse --short=8 HEAD);else F=unknown;S=unknown;fi;[[ $F != unknown ]]&&W="${W::-4}-${S}-${M}.zip"
mkdir -p "$O";rm -f "$L";touch "$L"||{ printf '%b\n' "${R}Unable to create build log!${N}";exit 1; }
l "==============================================";l "Kernel Build Log";l "==============================================";l "Started    : $(date)";l "Model      : $M";l "Addon      : $a";l "Commit     : $F";l "Short Hash : $S";l "Platform   : $PLATFORM_VERSION";l "Defconfig  : $DF";l "ZIP        : $W";l "==============================================";l ""
printf '\n';printf '%b\n' "${B}==============================================${N}";printf '%b\n' "${B}              (not) kernel build${N}";printf '%b\n' "${B}==============================================${N}";printf 'Model : %s\n' "$M";printf 'Addon : %s\n' "$a";printf 'Commit: %s\n' "$S";printf 'Log   : %s\n' "$L";printf '%b\n' "${B}==============================================${N}";printf '\n'
r "Updating git submodules" git submodule update --init --recursive||exit 1;export PATH="$T/bin:$PATH"
if [[ ! -x "$T/bin/clang" ]];then
printf '%b\n' "${Y}Clang not found! Downloading...${N}";mkdir -p "$T";l "";l ">>> Finding latest Neutron Clang release"
J="$(curl -fsSL https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/latest|jq -r '.assets[]|select(.name|endswith(".tar.zst"))|.browser_download_url'|head -n1)";printf '%s\n' "$J">>"$L"
[[ -z $J ]]&&{ printf '%b\n' "${R}✗ Failed to find latest release!${N}";l "Failed to find latest Clang release.";exit 1; }
r "Downloading Clang toolchain" bash -c 'curl -L "$1"|tar --zstd -x -C "$2" --strip-components=1' _ "$J" "$T"||exit 1;printf '%b\n' "${G}✓${N} Clang ready!"
else printf '%b\n' "${G}✓${N} Clang toolchain found";fi
printf '\n';printf '%b\n' "${B}Build configuration:${N}";printf '  Model      : %s\n' "$M";printf '  Addon      : %s\n' "$a";printf '  Defconfig  : %s\n' "$DF";printf '  Toolchain  : %s\n' "$T";printf '\n'
DA=("O=out" "ARCH=arm64");for x in $DF;do DA+=("$x");done;r "Generating kernel configuration" make "${DA[@]}"||exit 1;r "Running olddefconfig" make O=out ARCH=arm64 olddefconfig||exit 1
MA=("-j$(nproc --all)" O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1)
l "";l ">>> Removing previous boot output";rm -rf "$H"||{ printf '%b\n' "${R}✗ Failed to clean boot directory${N}";exit 1; }
printf '%b\n' "${G}Starting compilation...${N}";printf '\n';r "Building DTB and DTBO images" make "${MA[@]}" dtbo.img||exit 1
[[ -d "$D" ]]||{ printf '%b\n' "${R}✗ DTS directory missing: $D${N}";l "DTS directory missing: $D";exit 1; }
l "";l ">>> Generating DTB";cat $(find "$D" -type f -name "*.dtb"|sort)>"$H/dtb";printf '%b\n' "${G}✓${N} DTB + DTBO ready!";l "";l ">>> Generating Kernel";r "Building Kernel Image" make "${MA[@]}" Image.gz||exit 1
[[ -f "$H/Image.gz" ]]||{ printf '%b\n' "${R}✗ Compilation failed: Image.gz missing${N}";l "Image.gz missing after compilation.";exit 1; };printf '%b\n' "${G}✓${N} Kernel Image found!"
if [[ -d "$Q/AnyKernel3" ]];then printf '%b\n' "${G}✓${N} AnyKernel3 found! Skipping clone.";l "AnyKernel3 found. Skipping clone.";else r "Cloning AnyKernel3" git clone -q -b "$M" "$U" "$Q/AnyKernel3"||exit 1;fi
rm -f "$Q/AnyKernel3/dtbo.img" "$Q/AnyKernel3/Image.gz" "$Q/AnyKernel3/dtb";r "Copying kernel files" cp "$H/dtbo.img" "$H/Image.gz" "$H/dtb" "$Q/AnyKernel3/"||exit 1;rm -f "$Q"/*.zip;clear
r "Creating flashable ZIP" bash -c 'cd "$1"||exit 1;zip -r9 "../$2" * -x .git -x README.md -x "*placeholder"' _ "$Q/AnyKernel3" "$W"||exit 1
[[ -f "$Q/$W" ]]||{ printf '%b\n' "${R}✗ ZIP was not created${N}";l "ZIP was not created.";exit 1; };printf '%b\n' "${G}✓${N} Flashable ZIP created"
BT="$((SECONDS/60))m $((SECONDS%60))s";l "";l "==============================================";l "BUILD SUCCESSFUL";l "==============================================";l "ZIP        : $W";l "Build time : $BT";l "Finished   : $(date)";l "Log        : $L";l "=============================================="
printf '\n';printf '%b\n' "${G}==============================================${N}";printf '%b\n' "${G}             BUILD SUCCESSFUL${N}";printf '%b\n' "${G}==============================================${N}";printf 'Model      : %s\n' "$M";printf 'Addon      : %s\n' "$a";printf 'Commit     : %s\n' "$S";printf 'Zip        : %s\n' "$W";printf 'Build time : %s\n' "$BT";printf 'Build log  : %s\n' "$L";printf '%b\n' "${G}==============================================${N}"
