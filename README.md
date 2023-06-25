# uwsgi-podman-deploy
Proof of concept for zero downtime deployment with uwsgi running in podman container


```shell
systemctl --user link ./systemd/user/uwsgi-zergpool.service
systemctl --user link ./systemd/user/uwsgi-zergling.service
systemctl --user start uwsgi-zergling
systemctl --user reload uwsgi-zergling
```
