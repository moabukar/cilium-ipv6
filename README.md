# Cilium IPv6

This lab demonstrates how to set up and use Cilium with IPv6 in a Kubernetes environment. It covers cluster creation, Cilium installation, Hubble activation, and various IPv6 connectivity tests

## Setup

```
kind create cluster --config kind.yaml

cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=kind-control-plane \
  --set k8sServicePort=6443 \
  --set ipv6.enabled=true

cilium status --wait

cilium config view | grep ipv6

kubectl get nodes -o wide
kubectl describe nodes | grep PodCIDRs
```

## Activate Hubble

```

cilium hubble enable --ui

<!-- cilium hubble port-forward & -->
```

## Deploy pods

```
kubectl apply -f pod1.yaml -f pod2.yaml
```

## Test IPv6 ping Pod to pod

```
## Check the Pods have been successfully deployed. Notice it has two IP addresses allocated – IPv4 and IPv6.

kubectl describe pod pod-worker | grep -A 2 IPs
kubectl describe pod pod-worker2 | grep -A 2 IPs

## If no IP address is displayed, wait a few more seconds before re-running the command as the Pod might still be booting up.

## Let's directly get the IPv6 address from pod-worker2 with this command.
IPv6=$(kubectl get pod pod-worker2 -o jsonpath='{.status.podIPs[1].ip}')
echo $IPv6


# Let's run an IPv6 ping from pod-worker to pod-worker2. Because the Pods were pinned to different nodes, it should show successful IPv6 connectivity between Pods on different nodes.

kubectl exec -it pod-worker -- ping6 -c 5 $IPv6
```

## Test IPv6 ping Pod to service

```
## Notice the ipFamilyPolicy and ipFamilies Service settings in lines 30 to 33 required for IPv6.

kubectl apply -f echo-kube-ipv6.yaml
kubectl describe svc echoserver

ServiceIPv6=$(kubectl get svc echoserver -o jsonpath='{.spec.clusterIP}')
echo $ServiceIPv6

kubectl exec -i -t pod-worker -- curl -6 http://[$ServiceIPv6]/ | jq
```json
{
  "host": {
    "hostname": "[fd00:10:96::89b9]",
    "ip": "fd00:10:244:2::c9d",
    "ips": []
  },
  "http": {
    "method": "GET",
    "baseUrl": "",
    "originalUrl": "/",
    "protocol": "http"
  },
  "request": {
    "params": {
      "0": "/"
    },
    "query": {},
    "cookies": {},
    "body": {},
    "headers": {
      "host": "[fd00:10:96::89b9]",
      "user-agent": "curl/8.7.1",
      "accept": "*/*"
    }
  },
  "environment": {
    "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "HOSTNAME": "echoserver-5c96cdb7b5-hp26h",
    "NODE_VERSION": "20.11.0",
    "YARN_VERSION": "1.22.19",
    "PORT": "80",
    "ECHOSERVER_PORT_80_TCP_ADDR": "fd00:10:96::89b9",
    "KUBERNETES_SERVICE_PORT": "443",
    "KUBERNETES_PORT_443_TCP_PROTO": "tcp",
    "KUBERNETES_PORT_443_TCP_ADDR": "10.96.0.1",
    "ECHOSERVER_SERVICE_HOST": "fd00:10:96::89b9",
    "ECHOSERVER_PORT_80_TCP_PROTO": "tcp",
    "ECHOSERVER_PORT_80_TCP_PORT": "80",
    "KUBERNETES_SERVICE_PORT_HTTPS": "443",
    "ECHOSERVER_PORT": "tcp://[fd00:10:96::89b9]:80",
    "ECHOSERVER_PORT_80_TCP": "tcp://[fd00:10:96::89b9]:80",
    "KUBERNETES_PORT": "tcp://10.96.0.1:443",
    "KUBERNETES_PORT_443_TCP_PORT": "443",
    "ECHOSERVER_SERVICE_PORT": "80",
    "KUBERNETES_SERVICE_HOST": "10.96.0.1",
    "KUBERNETES_PORT_443_TCP": "tcp://10.96.0.1:443",
    "HOME": "/root"
  }
}
```

```

## Verify IPv6 DNS

```bash
kubectl exec -i -t pod-worker -- nslookup -q=AAAA echoserver.default

Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   echoserver.default.svc.cluster.local
Address: fd00:10:96::89b9

Well done - you have validated:

inter-node IPv6 connectivity with ICMPv6,
pod-to-Service IPv6 connectivity over HTTP,
DNS resolution for AAAA records.

```

## Using Hubble to monitor traffic of IPv6

```bash
## In >_ Terminal 1, enable Hubble Port Forwarding to visualize these flows:
cilium hubble port-forward &

## Let's head over to >_ Terminal 2 to run an IPv6 ping from pod-worker to pod-worker2.

IPv6=$(kubectl get pod pod-worker2 -o jsonpath='{.status.podIPs[1].ip}')
kubectl exec -it pod-worker -- ping -c 5 $IPv6

## Head back to >_ Terminal 1 to execute the hubble observe command to monitor the traffic flows.:
hubble observe --ipv6 --from-pod pod-worker

## Let's now print the node where the Pods are running with the --print-node-name:
hubble observe --ipv6 --from-pod pod-worker --print-node-name

## By default, Hubble will translate IP addresses to logical names such as Pod name or FQDN. You can disable it if you want the source and destination IPv6 addresses:
hubble observe --ipv6 --from-pod pod-worker \
  -o dict \
  --ip-translation=false \
  --protocol ICMPv6

## Head back to >_ Terminal 2 and run the curl to the IPv6 Service command again:
ServiceIPv6=$(kubectl get svc echoserver -o jsonpath='{.spec.clusterIP}')
echo $ServiceIPv6
kubectl exec -i -t pod-worker -- curl -6 http://[$ServiceIPv6]/ | jq

## In >_ Terminal 1, you will now see HTTP (with 80 as the DESTINATION port and TCP flags in the SUMMARY) and ICMPv6 flows:

hubble observe --ipv6 --from-pod pod-worker -o dict --ip-translation=false

## If you just want to see your ping messages, you can simply filter based on the protocol with the flag --protocol ICMPv6:

hubble observe --ipv6 --from-pod pod-worker -o dict --ip-translation=false --protocol ICMPv6
```
