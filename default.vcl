vcl 4.1;

backend default {
    .host = "nginx_test";
    .port = "80";
    .connect_timeout = 2s;

    .first_byte_timeout = 5s;
    .between_bytes_timeout = 5s;
}


sub vcl_recv {
  if (req.url ~ "(\?|&)(uuid)=") {
    #return(pass);
    set req.http.X-UUID = regsub(req.url, "^([^\?]+)(\?)", "");
    set req.url = regsuball(req.url, "(uuid)=[A-z0-9%._+-:]*&?", "");
    set req.url = regsub(req.url, "(\??&?)$", "");
  }
}
