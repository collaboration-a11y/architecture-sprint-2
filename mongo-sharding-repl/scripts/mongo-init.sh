#!/bin/bash

###
# Инициализируем бд
###

source .env

docker compose exec -T mongodb1 mongosh --port $MONGODB_DATABASE_PORT <<EOF
use $DATABASE_NAME
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

