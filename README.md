# k8s-prometheus-metrics-example
Example application with prometheus metrics based on kubernetes [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go)

Requirements:
* GKE/GCP kubernetes cluster in version 1.7+
* Running prometheus using [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* GNU Make
* openssl
* Bash

Consists of:
* Redis cluster with 1 master, 2 slaves that expose prometheus metrics using [oliver006/redis_exporter](https://github.com/oliver006/redis_exporter) sidecar container
* Modified [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go) application to include prometheus metrics
* Load generating application
* Haproxy as L7 loadbalancer for application
* Grafana dashboards for guestbook application, HAproxy, Redis

Deploy:
```bash
make deploy
```

Use dashboards in Grafana
* open [Grafana](http://localhost:8001/api/v1/proxy/namespaces/monitoring/services/grafana:3000)
* Sign in using credentials (default admin:admin)
* import dashboards by providing files from grafana directory


Clean:
```bash
make clean
```
