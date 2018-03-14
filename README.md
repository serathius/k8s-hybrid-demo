# k8s-logmon-demo
Setup for monitoring example application [guestbook-go](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook-go) on kubernetes

## Consists of:
* Redis cluster with 1 master, 2 slaves that expose prometheus metrics using [oliver006/redis_exporter](https://github.com/oliver006/redis_exporter) sidecar container
* Modified [guestbook-go](https://github.com/kubernetes/examples/tree/master/guestbook-go) application to include prometheus metrics
* Load generating application
* [EFK](https://docs.fluentd.org/v0.12/articles/docker-logging-efk-compose) stack for collecting logs from all nodes
* L7 loadbalancing using both HAProxy and Nginx
* Prometheus and Grafana deployments based on helm charts
* Grafana dashboards for guestbook application, HAProxy, Redis, Ngix
* Scripts to move all monitoring to dedicated node
* Hooks to interact with application/nodes that are not dedicated to monitoring

## Design
To get information about how cluster behaves during different situations we created hooks to interact with cluster.
One of concerns was hooks disturbing our monitoring, so we decided to separate monitoring.
To achieve that we deploy all monitoring, loadbalancing, load generator to separate instance, by marking one node with label 'purpose=monitoring'.
We add node affinities to our internal manifests and using kubectl patching we add nodeSelector to kube-prometheus CRDs/deployments.
With this we implemented hooks to skip nodes with that label.

## Requirements:
* GKE/GCP kubernetes cluster in version 1.8.x
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Helm](https://github.com/kubernetes/helm)
* GNU Make
* openssl
* Bash
* [jq](https://github.com/stedolan/jq)

## Deploy:
### From fresh cluster
* Authorize account (GCP)
  ```bash
  kubectl create clusterrolebinding i-am-root --clusterrole=cluster-admin --user=<your email>
  ```
* Install Tiller with RBAC
  ```bash
  make tiller
  ```
* Deploy LogMon Demo components
  ```bash
  make
  ```

##### Use dashboards in Grafana
* Get Grafana password
  ```bash
  make grafana-password
  ```
* Forward connection to grafana
  ```bash
  make grafana-forward
  ```
* Open [Grafana](http://localhost:3000)
* Sign into admin account using aquired password

## Hooks
Additional Requirements:
* [gcloud](https://cloud.google.com/sdk/)
### Break connection from node to master
Drops all packets on random node that are directed to master.
Will result in node changing state to unready.
Will be detected and fixed by auto-repair.
```bash
make hook-break-connection-from-node-to-master
```
It's one off command that can be reverted by running
```bash
make hook-break-connection-from-node-to-master
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

### Break connection from loadbalancer to node
Drops all packets on random node that are comming from LB.
Will result in loadbalancer marking pods on that node unhealthy and direct more traffic to the rest of them.
```bash
make hook-break-connection-from-node-to-lb
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
