{ config, pkgs, ... }:
{

  sops.secrets = {
    "grafana/secret_key" = { };
    "grafana/oidc_client_id" = { };
    "grafana/oidc_client_secret" = { };
  };

  services.grafana = {
    enable = true;
    declarativePlugins = with pkgs.grafanaPlugins; [
      # keep-sorted start
      grafana-metricsdrilldown-app
      victoriametrics-logs-datasource
      victoriametrics-metrics-datasource
      # keep-sorted end
    ];
    settings = {
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
      security = {
        admin_email = "i@rvf6.com";
        secret_key = "$__file{/run/credentials/grafana.service/secret_key}";
        cookie_secure = true;
      };
      server = {
        protocol = "socket";
        socket = "/run/grafana/grafana.sock";
        root_url = "https://grafana.rvf6.com";
      };
      auth = {
        login_maximum_inactive_lifetime_duration = "1h";
        disable_login_form = true;
        oauth_allow_insecure_email_lookup = false;
      };
      "auth.generic_oauth" = {
        name = "Pocket ID";
        enabled = true;
        allow_sign_up = false;
        auto_login = true;
        client_id = "$__file{/run/credentials/grafana.service/oidc_client_id}";
        client_secret = "$__file{/run/credentials/grafana.service/oidc_client_secret}";
        scopes = "openid profile email";
        email_attribute_name = "email:primary";
        auth_url = "https://pocket-id.rvf6.com/authorize";
        token_url = "https://pocket-id.rvf6.com/api/oidc/token";
        tls_skip_verify_insecure = false;
        tls_client_ca = "/etc/ssl/certs/ca-bundle.crt";
        use_pkce = true;
        skip_org_role_sync = true;
      };
      users.default_theme = "system";
    };
  };

  systemd.services.grafana.serviceConfig.LoadCredential = [
    "secret_key:${config.sops.secrets."grafana/secret_key".path}"
    "oidc_client_id:${config.sops.secrets."grafana/oidc_client_id".path}"
    "oidc_client_secret:${config.sops.secrets."grafana/oidc_client_secret".path}"
  ];

  presets.nginx.virtualHosts."grafana.rvf6.com".locations."/" = {
    proxyPass = "http://unix:${config.services.grafana.settings.server.socket}:/";
    proxyWebsockets = true;
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];

}
