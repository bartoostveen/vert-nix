{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkDefault
    mkMerge
    types
    recursiveUpdate
    pipe
    mapAttrsRecursive
    optionalAttrs
    toUpper
    isList
    concatStringsSep
    isBool
    boolToString
    collect
    isString
    listToAttrs
    optional
    optionalString
    getExe
    ;

  inherit (types)
    bool
    str
    nullOr
    attrs
    package
    path
    submodule
    enum
    port
    ;

  cfg = config.services.vert;

  defaultUser = "vertd";

  getEnv =
    set:
    pipe set [
      (mapAttrsRecursive (
        path: value:
        optionalAttrs (value != null) {
          name = toUpper (concatStringsSep "_" path);
          value =
            if isList value then
              concatStringsSep "," value
            else if isBool value then
              boolToString value
            else
              toString value;
        }
      ))
      (collect (x: isString x.name or false && isString x.value or false))
      listToAttrs
    ];
  environment = getEnv cfg.settings;
  webEnvironment = getEnv cfg.webSettings;
in
{
  options.services.vert = {
    enable = mkEnableOption "vert, The next-generation file converter. Open source, fully local* and free forever";
    webPackage = mkOption {
      description = "The built distribution of the vert web interface";
      type = package;
      default = pkgs.vert.web;
    };
    vertdPackage = mkOption {
      description = "The vertd package";
      type = package;
      default = pkgs.vert.vertd;
    };
    hostName = mkOption {
      description = "The host name of the vert daemon, as accessible by the browser";
      type = str;
      example = "vert.local";
    };
    user = mkOption {
      default = defaultUser;
      description = "User vertd runs as.";
      type = types.str;
    };
    group = mkOption {
      default = defaultUser;
      description = "Group vertd runs as.";
      type = types.str;
    };
    suppressFirewallWarning = mkEnableOption "suppressing the warning that occurs when vertd is both proxied and opened in the firewall";
    openFirewall = mkOption {
      description = "Whether to open the firewall for the vertd port";
      type = bool;
      default = false;
      example = true;
    };
    environmentFile = mkOption {
      description = "Path to a file containing environment variables";
      type = nullOr path;
      default = null;
      example = "/run/secrets/vert.env";
    };
    port = mkOption {
      description = ''
        The port that vertd listens on.

        ::: {.note}
        This is a read-only option that is read from {option}`services.vert.settings.port`. 
        :::
      '';
      type = port;
      default = cfg.settings.port;
      defaultText = lib.literalExpression "config.services.vert.settings.port";
      readOnly = true;
    };
    # TODO: better option descriptions
    settings = mkOption {
      description = "Settings for vertd";
      type = submodule {
        freeformType = attrs;
        options = {
          port = mkOption {
            description = "Port of the vertd daemon";
            type = port;
            default = 24153;
            example = 7777;
          };
          webhook = {
            url = mkOption {
              description = "if set, vertd will attempt to notify you via a discord webhook when a video fails to convert";
              type = nullOr str;
              default = null;
            };
            pings = mkOption {
              description = "webhook pings -- these will be formatted into the main message";
              type = nullOr str;
              default = null;
              example = "<@&role_id> <@user_id>";
            };
          };
          admin.password = mkOption {
            description = ''
              admin password for kept videos

              ::: {.warning}
              Never use this in production! Set {option}`services.vertd.environmentFile` to a file containing the `ADMIN_PASSWORD` environment variable instead!
              :::
            '';
            type = nullOr str;
          };
          force_gpu = mkOption {
            description = "If vertd can't detect your GPU type or detects the wrong one, you can force vertd to use hardware acceleration for a specific vendor manually";
            type = nullOr (enum [
              "nvidia"
              "amd"
              "intel"
              "apple"
              "cpu"
            ]);
            default = null;
            example = "nvidia";
          };
        };
      };
      default = { };
    };
    webSettings = mkOption {
      description = "Settings for the web interface, has defaults for proxied nginx if enabled using {option}`services.vertd.nginx.enable`";
      type = submodule {
        freeformType = attrs;
        options = {
          hostname = mkOption {
            description = "Host name of this web interface";
            type = str;
            example = "vert.local";
          };
          vertd.url = mkOption {
            description = "URL to vertd";
            type = str;
            example = "https://vertd.vert.sh";
          };
        };
      };
      default = { };
    };
    nginx = mkOption {
      type = submodule (
        recursiveUpdate
          (import "${modulesPath}/services/web-servers/nginx/vhost-options.nix" {
            inherit config lib;
          })
          {
            options.enable = mkEnableOption "nginx integration for vertd";
          }
      );
      default = { };
      example = ''
        {
          serverAliases = [
            "vert.''${config.networking.domain}"
          ];
          # To enable encryption and let let's encrypt take care of certificate
          forceSSL = true;
          enableACME = true;
        }
      '';
      description = ''
        With this option, you can customize the nginx virtualHost settings.
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings =
      optional (cfg.nginx.enable && cfg.openFirewall && !cfg.suppressFirewallWarning)
        "Vertd is already proxied through nginx, you should consider not exposing this port or suppressing it using services.vertd.suppressFirewallWarning = true;";

    services.vert = {
      webSettings = {
        hostname = mkDefault cfg.hostName;
        vertd.url = mkDefault (
          if cfg.nginx.enable then
            "http${optionalString cfg.nginx.forceSSL "s"}://${cfg.hostName}/daemon"
          else
            "http://${cfg.hostName}:${toString cfg.port}"
        );
      };
      nginx.serverName = mkDefault cfg.hostName;
    };

    systemd.services.vertd = {
      description = "vertd, The next-generation file converter. Open source, fully local* and free forever";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      inherit environment;
      path = [
        cfg.vertdPackage
        pkgs.ffmpeg-headless
      ];
      serviceConfig = {
        Type = "simple";
        ExecStart = getExe cfg.vertdPackage;
        DynamicUser = true;
        User = cfg.user;
        Group = cfg.group;
        EnvironmentFile = cfg.environmentFile;
        StateDirectory = "vertd";
        WorkingDirectory = "%S/vertd";
        Restart = "on-failure";
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MountAPIVFS = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = "strict";
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = 27;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    services.nginx = mkIf cfg.nginx.enable {
      enable = mkDefault true;
      virtualHosts.${cfg.nginx.serverName} = mkMerge [
        (removeAttrs cfg.nginx [
          "enable"
          "root"
        ])
        {
          root = cfg.webPackage.override { env = webEnvironment; };
          locations."/daemon/" = {
            proxyPass = "http://localhost:${toString cfg.port}/";
            proxyWebsockets = true;
          };
        }
      ];
    };

    users = {
      users = mkIf (cfg.user == defaultUser) {
        ${defaultUser} = {
          inherit (cfg) group;
          isSystemUser = true;
        };
        "${config.services.nginx.user}".extraGroups = [ cfg.group ];
      };
      groups = mkIf (cfg.group == defaultUser) { ${defaultUser} = { }; };
    };
  };
}
