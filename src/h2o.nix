{
  listen = 8080;
  access-log = "/dev/stdout";
  error-log = "/dev/stderr";

  compress = "ON";

  "http1-upgrade-to-http2" = "OFF";
  "proxy.preserve-x-forwarded-proto" = "ON";

  hosts = {
    "0.0.0.0:8080" = {
      paths = {
        "/" = {
          "file.dir" = "/var/lib/freshrss/p";
          "file.index" = [ "index.php" "index.html" "index.htm" ];
          "file.custom-handler" = {
            "extension" = ".php";
            "fastcgi.connect" = {
              host = "127.0.0.1";
              port = "9999";
              type = "tcp";
            };
          };
        };
      };
    };
  };
}
