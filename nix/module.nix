# TODO: use systemD services instead of containers, the nix way.
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.services.universe;
in {
  config = lib.mkIf cfg.enable {
    ###################################################################
    # user                                                            #
    ###################################################################

    users.users.universe = {
      home = "/data/uni-verse";
      group = "universe";
      isSystemUser = true;
    };

    users.groups.universe.members = ["universe"];

    ###################################################################
    # Services                                                        #
    ###################################################################

    systemd.tmpfiles.rules = [
      "d /data/uni-verse/api-logs 755 root root"
      "d /data/uni-verse/mongo-data 755 root root"
      "d /data/uni-verse/minio-data 755 root root"
      "d /data/uni-verse/elasticsearch-data 755 root root"
      "d /data/uni-verse/rabbitmq-data 755 root root"
      "d /data/uni-verse/rabbitmq-logs 755 root root"
    ];

    virtualisation.oci-containers.containers = {
      uni-verse-api = {
        autoStart = true;
        image = "ewr.vultrcr.com/vagahbond/uni-verse/api";
        dependsOn = ["uni-verse-mongo" "uni-verse-minio" "uni-verse-rabbitmq"];
        environmentFiles = [
          cfg.envFile
        ];
        volumes = [
          "/data/uni-verse/api-logs:/usr/src/app/logs"
        ];
        hostname = "uapi";
        ports = ["3000:3000" "3001:9229"];
      };
      uni-verse-frontend = {
        autoStart = true;
        image = "ewr.vultrcr.com/vagahbond/uni-verse/frontend";
        dependsOn = ["uni-verse-mongo" "uni-verse-minio" "uni-verse-rabbitmq" "uni-verse-api"];
        environmentFiles = [
          cfg.envFile
        ];
        hostname = "ufrontend";
        ports = ["3006:3000"];
      };
      uni-verse-mongo = {
        autoStart = true;
        image = "docker.io/library/mongo:latest";
        environmentFiles = [
          cfg.envFile
        ];
        volumes = [
          "/data/uni-verse/mongo-data:/data/db"
        ];
        hostname = "umongo";
        ports = [];
      };

      uni-verse-mongoExpress = {
        autoStart = true;
        image = "docker.io/library/mongo-express:latest";
        environmentFiles = [
          cfg.envFile
        ];
        hostname = "umongo-express";
        ports = ["8086:8081"];
      };
      uni-verse-minio = {
        autoStart = true;
        image = "quay.io/minio/minio:latest";
        environmentFiles = [
          cfg.envFile
        ];
        volumes = [
          "/data/uni-verse/minio-data:/data"
        ];
        entrypoint = "/bin/minio";
        cmd = ["server" "--console-address" ":9001" "/data"];
        hostname = "uminio";
        ports = ["9000:9000" "9001:9001"];
      };
      uni-verse-rabbitmq = {
        autoStart = true;
        image = "docker.io/library/rabbitmq:latest";
        environmentFiles = [
          cfg.envFile
        ];
        volumes = [
          "/data/uni-verse/rabbitmq-data:/var/lib/rabbitmq"
          "/data/uni-verse/rabbitmq-logs:/var/log/rabbitmq"
        ];
        hostname = "urabbitmq";
        ports = [];
      };
      uni-verse-elasticsearch = {
        autoStart = true;
        image = "docker.elastic.co/elasticsearch/elasticsearch:8.14.0";
        environment = {
          "discovery.type" = "single-node";
          "node.name" = "es01";
          "cluster.name" = "docker-cluster";
          "bootstrap.memory_lock" = "false";
          "xpack.security.enabled" = "false";
          "ES_JAVA_OPTS" = "-Xms512m -Xmx512m";
        };
        environmentFiles = [
          cfg.envFile
        ];
        volumes = [
          "/data/uni-verse/elasticsearch-data/data:/usr/share/elasticsearch/data:rw,U"
        ];
        hostname = "uelasticsearch";
        ports = [];
      };
    };

    ###################################################################
    # proxies                                                         #
    ###################################################################

    services.nginx = {
      enable = true;
      virtualHosts = {
        "uni-verse.api.vagahbond.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
        "uni-verse.vagahbond.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3006";
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
        "uni-verse.minio.vagahbond.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9000";
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
        "uni-verse.minio.console.vagahbond.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9001";
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
        "uni-verse.mongoexpress.vagahbond.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8086";
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
      };
    };
  };
}
