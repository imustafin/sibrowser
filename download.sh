#!/bin/bash

heroku pg:backups:capture && heroku pg:backups:download
