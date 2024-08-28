#!/bin/bash

grafana-server --homepath="$GF_PATHS_HOME" --config="$GF_PATHS_CONFIG" cfg:default.paths.data="$GF_PATHS_DATA" & sleep 10 &&

curl -XPOST -H 'Content-Type: application/json' -d '{ "name": "Common ERSD Mailer", "type":  "webhook", "isDefault": true, "sendReminder": false, "settings":{"autoResolve":true,"httpMethod":"POST","uploadImage":true,"url":"http://mailer:3001/mailer"} }' http://admin:admin@localhost:3000/api/alert-notifications

curl -XPOST -H 'Content-Type: application/json' -d '{ "name":"viewer", "email":"viewer@thunderbee.com", "login":"viewer", "password":"'$GRAFANA_VIEWER_PASSWORD'", "homeDashboardId":6, "isAdmin": false }' http://admin:admin@localhost:3000/api/admin/users

curl -X PUT -H 'Content-Type: application/json' -d '{ "homeDashboardId":6 }' http://viewer:$GRAFANA_VIEWER_PASSWORD@localhost:3000/api/user/preferences

curl -X PUT -H 'Content-Type: application/json' -d '{ "oldPassword": "admin", "newPassword":"'$GRAFANA_ADMIN_PASSWORD'", "confirmNew": "'$GRAFANA_ADMIN_PASSWORD'" }' http://admin:admin@localhost:3000/api/user/password
