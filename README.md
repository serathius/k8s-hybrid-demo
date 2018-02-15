# k8s-prometheus-metrics-example
Example application with prometheus metrics based on kubernetes [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go)

## Consists of:
* Redis cluster with 1 master, 2 slaves that expose prometheus metrics using [oliver006/redis_exporter](https://github.com/oliver006/redis_exporter) sidecar container
* Modified [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go) application to include prometheus metrics
* Load generating application
* Haproxy as L7 loadbalancer for application
* Grafana dashboards for guestbook application, HAproxy, Redis
* Scripts to move all monitoring to dedicated node
* Hooks to interact with application/nodes that are not dedicated to monitoring

## Design
To get information about how cluster behaves during different situations we created hooks to interact with cluster.
One of concerns was hooks disturbing our monitoring, so we decided to separate monitoring.
To achieve that we deploy all monitoring, loadbalancing, load generator to separate instance, by marking one node with label 'purpose=monitoring'.
We add node affinities to our internal manifests and using kubectl patching we add nodeSelector to kube-prometheus CRDs/deployments.
With this we implemented hooks to skip nodes with that label.

## Requirements:
* GKE/GCP kubernetes cluster in version 1.7+
* Running prometheus using [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* GNU Make
* openssl
* Bash

## Deploy:
```bash
make
```

## Use dashboards in Grafana
* Open [Grafana](http://localhost:8001/api/v1/proxy/namespaces/monitoring/services/grafana:3000)
* Sign in using credentials (default admin:admin)
* Import dashboards by providing files from grafana directory


## Hooks
### Break node
Disrupts node to master communications. Useful to test node auto-repair.
```bash
make hook-break-node
```
To fix node manually
```bash
make hook-break-node-revert
```
### Overload application

Increases traffic significantly. Useful to test HPA
```bash
make hook-overload-frontend
```
Restore normal traffic
```bash
make hook-overload-frontend-revert
```
### Clear Redis
Runs FLUSHALL on Redis master
```bash
make hook-clear-redis-records
```

### Break pod
Disrupts communication between loadbalancer and application pods on one instance
```bash
make hook-break-pod-application
```

### Delete pod
Deletes random pod from selected group
```bash
make hook-delete-pod-application
make hook-delete-pod-redis-master
make hook-delete-pod-redis-slave
```

## Clean:
```bash
make clean
```
