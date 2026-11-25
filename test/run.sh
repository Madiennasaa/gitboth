#!/usr/bin/env bash
# Smoke test gitboth: pakai repo sementara dengan dua bare remote.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT=$ROOT/gitboth
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=$TMP/gitconfig
: >"$GIT_CONFIG_GLOBAL"

new_repo() {
	rm -rf "$TMP/work" "$TMP/a.git" "$TMP/b.git"
	git init -q --bare "$TMP/a.git"
	git init -q --bare "$TMP/b.git"
	git init -q -b main "$TMP/work"
	cd "$TMP/work"
	git remote add origin "$TMP/a.git"
	git remote add gitlab "$TMP/b.git"
	echo "halo" >file.txt
}

head_of() { git -C "$1" rev-parse --verify -q refs/heads/main 2>/dev/null || true; }

# 1. commit + push ke dua remote
new_repo
out=$("$SCRIPT" "feat: commit pertama" 2>&1) || { no "commit+push exit"; cat <<<"$out"; }
if [ "$(head_of "$TMP/a.git")" = "$(git rev-parse HEAD)" ] && [ "$(head_of "$TMP/b.git")" = "$(git rev-parse HEAD)" ]; then
	ok "push ke dua remote"
else
	no "push ke dua remote"
fi

# 2. tanpa perubahan: tidak bikin commit baru, tetap push
before=$(git rev-parse HEAD)
"$SCRIPT" >/dev/null 2>&1 || no "jalan tanpa perubahan"
[ "$(git rev-parse HEAD)" = "$before" ] && ok "tanpa perubahan tidak commit" || no "tanpa perubahan tidak commit"

# 3. remote duplikat hanya dipush sekali
new_repo
git remote add mirror "$TMP/a.git"
out=$("$SCRIPT" -n "x" 2>&1)
count=$(grep -c '^\[dry-run\] push:' <<<"$out")
labels=$(grep '^\[dry-run\] push:' <<<"$out" | awk '{print $3}' | sort | tr '\n' ' ')
[ "$count" = 2 ] && [ "$labels" = "gitlab mirror " ] && ok "url duplikat dilewati" ||
	no "remote duplikat tidak dilewati (dapat: $labels)"

# 4. perubahan tapi pesan kosong -> gagal, tidak commit
new_repo
if "$SCRIPT" >/dev/null 2>&1; then no "pesan kosong ditolak"; else ok "pesan kosong ditolak"; fi
[ -z "$(head_of "$TMP/a.git")" ] && ok "tidak ada push saat gagal" || no "tidak ada push saat gagal"

# 5. -s hanya commit yang staged
new_repo
git add file.txt
echo "lain" >lain.txt
"$SCRIPT" -s "chore: staged saja" >/dev/null 2>&1
if git ls-tree -r --name-only HEAD | grep -qx 'lain.txt'; then no "-s tidak ikut untracked"; else ok "-s tidak ikut untracked"; fi

# 7. -r hanya push remote yang dipilih
new_repo
"$SCRIPT" -r gitlab "feat: hanya gitlab" >/dev/null 2>&1
if [ -n "$(head_of "$TMP/b.git")" ] && [ -z "$(head_of "$TMP/a.git")" ]; then
	ok "-r hanya push remote terpilih"
else
	no "-r hanya push remote terpilih"
fi
if "$SCRIPT" -r tidakada "x" >/dev/null 2>&1; then no "-r tanpa match ditolak"; else ok "-r tanpa match ditolak"; fi

# 8. satu remote gagal: remote lain tetap dipush, exit 1
new_repo
git remote set-url --push gitlab "$TMP/tidak-ada.git"
if "$SCRIPT" "fix: remote kedua mati" >/dev/null 2>&1; then
	no "push gagal memberi exit 1"
else
	ok "push gagal memberi exit 1"
fi
[ -n "$(head_of "$TMP/a.git")" ] && ok "remote sehat tetap terpush" || no "remote sehat tetap terpush"

# 9. tolak saat merge belum selesai
new_repo
echo "deadbeef" >.git/MERGE_HEAD
before=$(git rev-parse HEAD 2>/dev/null || echo "-")
if "$SCRIPT" "chore: saat merge" >/dev/null 2>&1; then
	no "merge belum selesai ditolak"
else
	after=$(git rev-parse HEAD 2>/dev/null || echo "-")
	[ "$before" = "$after" ] && ok "merge belum selesai ditolak" || no "merge belum selesai ditolak"
fi

# 10. -c memverifikasi ref remote setelah push
new_repo
out=$("$SCRIPT" -c "feat: dengan verifikasi" 2>&1) || no "-c exit 0"
n=$(grep -c "^gitboth: ok " <<<"$out" || true)
[ "$n" = 2 ] && ok "-c verifikasi kedua remote" || no "-c verifikasi kedua remote (dapat: $n)"

# 6. bukan repo git -> error
mkdir -p "$TMP/plain" && cd "$TMP/plain"
if "$SCRIPT" "x" >/dev/null 2>&1; then no "tolak non-repo"; else ok "tolak non-repo"; fi

printf '\n%d lulus, %d gagal\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
