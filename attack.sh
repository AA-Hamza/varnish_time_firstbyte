vegeta_bin="./bin/vegeta"
number_of_requests=40000

function install-vegeta {
	mkdir -p ./bin
	wget https://github.com/tsenart/vegeta/releases/download/v12.12.0/vegeta_12.12.0_linux_amd64.tar.gz -O ./bin/vegeta_12.12.0_linux_amd64.tar.gz
	cd bin
	tar -xvf vegeta_12.12.0_linux_amd64.tar.gz 
	cd ..
}

if [ ! -e "$vegeta_bin" ]; then
	install-vegeta
fi

ulimit -n $(( 1024 * 16 ))
awk -v n=${number_of_requests} -v a=$(date +%s) 'BEGIN{for (i=1; i<=n; i++) printf("GET http://localhost:8081?uuid=%d-%d\n", a, i)}' | ${vegeta_bin} attack -lazy -duration=0 -rate 0 -max-workers 100 -timeout 50s -max-body 0 | ${vegeta_bin} report --every 5s | grep -v "Get"
