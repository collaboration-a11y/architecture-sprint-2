#!/bin/bash

source .env

# Инициализация конфигурационного сервера

echo "Инициализируем конфигурационный сервер"

docker compose exec -T configSvr mongosh --port $CONFIG_SVR_PORT <<EOF
rs.initiate({ _id: "config_server", configsvr: true, members: [ { _id: 0, host: "configSvr:$CONFIG_SVR_PORT" } ]});
exit();
EOF

# Инициализируем шарды

echo "Инициализируем поочердно шарды"

docker compose exec -T shard1 mongosh --port $SH_PORT_1 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:$SH_PORT_1" },
      ]
    }
);
exit();
EOF

docker compose exec -T shard2 mongosh --port $SH_PORT_2 <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 1, host : "shard2:$SH_PORT_2" },
      ]
    }
);
EOF

# Инициализируем роутер 

echo "Добавляем созданные шарды в настройку роутера и включаем шардирование"

docker compose exec -T mongos_router mongosh --port $MONGOS_ROUTER_PORT <<EOF
sh.addShard("shard1/shard1:$SH_PORT_1");
sh.addShard("shard2/shard2:$SH_PORT_2");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

db.helloDoc.countDocuments()
exit();

EOF


# Заполняем базу тестовыми данными
# Проверяем что все корректно зашардилось

echo "Выводим количество документов в каждом из шардов"

docker compose exec -T shard1 mongosh --port $SH_PORT_1 <<EOF
use $DATABASE_NAME
db.helloDoc.countDocuments()
exit();
EOF

echo "Выводим количество документов в каждом из шардов"

docker compose exec -T shard2 mongosh --port $SH_PORT_2 <<EOF
use $DATABASE_NAME
db.helloDoc.countDocuments()
exit();
EOF

