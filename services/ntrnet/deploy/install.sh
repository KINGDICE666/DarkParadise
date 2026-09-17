#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root after extracting the release into /srv/ntrnet.\n' >&2
    exit 1
fi

cd /srv/ntrnet
test -f /etc/ntrnet.env
if ! id ntrnet >/dev/null 2>&1; then
    useradd --system --home /nonexistent --shell /usr/sbin/nologin ntrnet
fi
install -d -o ntrnet -g ntrnet -m 0755 /srv/ntrnet-media
python3 -m venv .venv
.venv/bin/python -m pip install --disable-pip-version-check -r requirements.lock
chmod -R a+rX .venv
set -a
. /etc/ntrnet.env
set +a
.venv/bin/python manage.py init-db
.venv/bin/python manage.py migrate
install -m 0644 deploy/ntrnet.service deploy/ntrnet-cleanup.service deploy/ntrnet-cleanup.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now ntrnet.service ntrnet-cleanup.timer
systemctl --no-pager --full status ntrnet.service
