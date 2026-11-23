# gitboth

Satu perintah untuk commit lalu push ke **semua remote** repo (GitHub + GitLab, dst).

Repo yang punya dua remote biasanya butuh dua perintah push. `gitboth` menyatukannya,
dan otomatis melewati remote yang URL push-nya duplikat supaya tidak push dua kali.

## Pakai

```bash
gitboth "fix: perbaiki typo di README"
gitboth -s "chore: commit yang sudah di-stage saja"
gitboth -n "test: lihat rencana dulu"     # dry-run, tidak mengubah apa pun
```

Tanpa pesan, `gitboth` hanya push commit yang belum terkirim:

```bash
gitboth
```

## Yang dilakukan

1. `git add -A` (kecuali `-s`).
2. Commit bila ada perubahan; kalau tidak ada, dilewati.
3. Push branch aktif ke setiap remote unik dengan `refs/heads/<branch>:refs/heads/<branch>`.

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
