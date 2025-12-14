# chase-roohms/docker-compose

## Useful Aliases
```shell
alias dockdate="docker compose pull && docker compose up -d"
alias dockdate_all="bash /home/neonvariant/docker/docker-compose/scripts/update-all-stacks.sh /home/neonvariant/docker/docker-compose/REPLACEME"
```

## Setting up a machine
```shell
git clone --no-checkout https://github.com/chase-roohms/docker-compose.git
cd ./docker-compose
git sparse-checkout init --no-cone

git sparse-checkout set \
  /.gitignore \
  /scripts/** \
  /REPLACEME/**

git checkout
git pull
```
