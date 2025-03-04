# Varnish time to first byte issue

## Description
This repo tries to replicate an *issue* in varnish where under some conditions, the time to first byte limit is not respected.

## Contents
- Docker compose that brings up nginx & varnish
- `inside_varnish_container.sh`, a script that needs to run inside varnish container.
    - it initalizes the logs
    - Opens tmux with logs on one pane and varnishstat on another pane
- `default.vcl` this is varnish vcl. it strips the uuid from the request and stores it in a header
- `nginx.conf`. serves the static content and sets the `Vary: X-UUID` header.
- `static-web` contains the static website that we are hosting
- `analyze.sh` use it against the access.log from varnish to get stats about the request like the p50, p90, p99
- `attack.sh` generates a lot of random requests to the site

## How to replicate
1. Init varnish & nginx
```bash
docker compose up -d
```
2. Exec the `inside_varnish_container.sh` script inside the varnish container, this will open tmux & you will see the stats & the logs
```bash
azureuser@varnish:~$ sudo docker exec -it varnish-varnish-1 bash
root@236790560b01:/etc/varnish# ./inside_varnish_container.sh
```
3. In another terminal, open 4 instances of the `./attack.sh` script. 
4. After the attacks are finished, you will have the `./access.log` file with the requests information. Run the `analyze.sh` script
```bash
azureuser@varnish:~/varnish$ ./analyze.sh access.log
File:                                   access.log
Total Matched:                          160000
Unique Requests:                        160000
Unique Percentage:                      100.00%
Hit Count:                              0
Hit Percentage:                         0.00%
Repeated Requests:                      0.00%
Miss Percentage:                        100.00%
P50:                                    3.648756s (# Requests slower: 80000)
P90:                                    14.573747s (# Requests slower: 16000)
P95:                                    19.415144s (# Requests slower: 8000)
P99:                                    30.757543s (# Requests slower: 1600)
Slowest request:                        87.895929s
--------------------
```



## If you pass the requests (comment in `default.vcl`), the time to first byte is respected
```bash
azureuser@varnish:~/varnish$ ./analyze.sh access.log
File:                                   access.log.bak
Total Matched:                          160000
Unique Requests:                        160000
Unique Percentage:                      100.00%
Hit Count:                              0
Hit Percentage:                         0.00%
Repeated Requests:                      0.00%
Miss Percentage:                        100.00%
P50:                                    0.016780s (# Requests slower: 80000)
P90:                                    2.020970s (# Requests slower: 16000)
P95:                                    5.013318s (# Requests slower: 8000)
P99:                                    5.213179s (# Requests slower: 1600)
--------------------
```


## Notes
- When we store a lot of requests with the issue, the attack might take a lot of time. so you can just test with one instance.
- CPU & Memory utalization was not full during any of the tests.
- I am using an azure instance with 4GB of memory for testing. 
