# sibrowser
SIGame Package Browser. See it live at <https://www.sibrowser.ru/>.

## Development
Run docker-compose:
```
docker-compose up
```

Run rails and other commands in docker-compose:
```
docker-compose exec app bash

./bin/dev
```


## Heroku db
Outside of docker run `download.sh`. It saves dump as `latest.dump.X`.

To load the dump run `restore.sh Y` where `Y` is the dump filename (`latest.dump.X`).
