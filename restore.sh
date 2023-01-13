#!/bin/bash

psql -c "create schema if not exists heroku_ext"
pg_restore --verbose --clean --no-acl --no-owner -h pg -U postgres -d sibrowser_development $1
