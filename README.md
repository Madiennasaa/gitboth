# gitboth

Satu perintah untuk commit lalu push ke **semua remote** repo (GitHub + GitLab, dst).

Repo yang punya dua remote biasanya butuh dua perintah push. `gitboth` menyatukannya,
dan otomatis melewati remote yang URL push-nya duplikat supaya tidak push dua kali.

## Pakai

```bash
gitboth "fix: perbaiki typo di README"
gitboth -s "chore: commit yang sudah di-stage saja"
gitboth -r github "feat: push ke GitHub saja"   # pola nama remote, boleh diulang
gitboth -c "feat: push lalu pastikan ref remote sama"  # verifikasi setelah push
gitboth -f "fix: tulis ulang commit setelah amend/rebase"  # force-with-lease
gitboth -n "test: lihat rencana dulu"           # dry-run, tidak mengubah apa pun
```

Tanpa pesan, `gitboth` hanya push commit yang belum terkirim:

```bash
gitboth
```

## Yang dilakukan

1. Tolak jalan bila repo sedang merge, cherry-pick, revert, atau rebase.
2. `git add -A` (kecuali `-s`).
3. Commit bila ada perubahan; kalau tidak ada, dilewati.
4. Push branch aktif ke setiap remote unik dengan `refs/heads/<branch>:refs/heads/<branch>`.
5. Dengan `-c`, bandingkan `git ls-remote` tiap remote dengan commit lokal; ref yang berbeda dihitung gagal.
6. Dengan `-f`, push memakai `--force-with-lease=<branch>:<sha remote>`; remote hanya ditimpa kalau belum bergerak, jadi tidak menimpa push orang lain.
7. Kalau satu remote gagal, remote lain tetap dipush, lalu exit code 1 dengan ringkasan remote yang gagal.

Setiap URL push yang sama hanya dipush sekali. Jadi remote `origin` yang punya
dua push URL (GitLab + GitHub) cukup satu jalan, dan remote lain yang menunjuk
URL yang sudah dipush otomatis dilewati.

## Pasang

```bash
install -m 755 gitboth ~/.local/bin/gitboth
```

## Test

```bash
./test/run.sh
```
