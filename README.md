# chase-roohms/docker-compose

## Useful Aliases
```shell
alias dockdate="docker compose pull && docker compose up -d"
```

## Setting up a machine
```shell
git clone --no-checkout https://github.com/chase-roohms/docker-compose.git
cd ./docker-compose
git sparse-checkout init --no-cone

git sparse-checkout set \
  /replace-me/** \
  .gitignore

git checkout -b main origin/main
```
