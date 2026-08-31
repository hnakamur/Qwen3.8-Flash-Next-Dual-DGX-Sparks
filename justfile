recipe_dir := `pwd`

rebase:
  cd "{{recipe_dir}}"
  git fetch origin
  if [ "$(git rev-parse main)" = "$(git rev-parse origin/main)" ]; then echo 'no update, exit.'; exit 0; fi
  git switch main
  git reset --hard origin/main
  git switch add_my_justfile
  git rebase main
  git push --force-with-lease hnakamur main add_my_justfile
  just env

sync:
  ssh pgx2 '\
  cd "{{recipe_dir}}" && \
  pwd && \
  git fetch origin && \
  git switch main && \
  git reset --hard origin/main \
  '
  rsync .env "pgx2:{{recipe_dir}}"

  ssh pgx1 '\
  cd "{{recipe_dir}}" && \
  git fetch origin && \
  git switch main && \
  git reset --hard origin/main \
  '
  rsync .env "pgx1:{{recipe_dir}}"

start:
  ssh pgx1 '\
    cd "{{recipe_dir}}" && \
    NCCL_HOST_DIR=/usr/lib/aarch64-linux-gnu WORKER_NCCL_HOST_DIR=/usr/lib/aarch64-linux-gnu ./start.sh \
  '

stop:
  ssh pgx1 'cd "{{recipe_dir}}" && ./stop.sh'

env:
  sed 's/^HEAD_IP=.*/HEAD_IP=192.168.177.11/;\
    s/^WORKER_IP=.*/WORKER_IP=192.168.177.12/;\
    s/^IFACE=.*/IFACE=enp1s0f1np1/;\
    s/^IB_HCA=.*/IB_HCA=rocep1s0f1/;\
    s/^IB_GID_INDEX=.*/IB_GID_INDEX=2/;\
    s/^PORT=.*/PORT=8000/;\
  ' .env.sample > .env
