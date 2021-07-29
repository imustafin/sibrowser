# sibrowser
SIGame Pack Browser. See it live at <https://www.sibrowser.ru/>.

## Development
Run docker-compose:
```
docker-compose -f docker-compose.development.yml up --build
```

Run rails and other commands in docker-compose:
```
docker-compose -f docker-compose.development.yml exec app bundle exec rails s -b 0.0.0.0
```
