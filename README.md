# k8s-prometheus-metrics-example
Example application with prometheus metrics based on kubernetes [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go)

Requirements:
* Running kubernetes cluster with running [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) cluster-monitoring setup

Consists of:
* Redis cluster with 1 master, 2 slaves that expose prometheus metrics using [oliver006/redis_exporter](https://github.com/oliver006/redis_exporter) sidecar container
* Modified [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go) application to include prometheus metrics
* Load generating application
* Grafana Dashboard template

Deploy:
```bash
make deploy
```


Access to Grafana
* open [Grafana](http://localhost:8001/api/v1/proxy/namespaces/monitoring/services/grafana:3000)
* login using credentials (default admin:admin)
* import dashboard template by providing file `grafana/guestbook.json`


Clean:
```bash
make clean
```
