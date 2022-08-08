#!/bin/bash

pg_restore --verbose --clean --no-acl --no-owner -h pg -U postgres -d sibrowser_development $1
