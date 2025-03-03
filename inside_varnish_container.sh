apt update -y; apt install jq tmux -y;

# Start collecting logs
/usr/local/bin/varnishncsa -F '{"timestamp": "%{%Y-%m-%dT%H:%M:%S%z}t", "method": "%m", "host": "%{Host}i", "url": "%U", "query": "%q", "hitmiss": "%{Varnish:hitmiss}x", "handling": "%{Varnish:handling}x", "time_firstbyte": "%{Varnish:time_firstbyte}x"}' -w /var/log/varnish/access.log &> /dev/null & disown

tmux new-session \; \
  send-keys 'tail -f /var/log/varnish/access.log | jq ".timestamp + \" \" + .time_firstbyte + \" \" + .handling + \" \" + .hitmiss + \" \" + .host + .url + .query"' C-m \; \
  split-window -h \; \
  send-keys 'varnishstat' C-m \; \
  select-pane -t 0
