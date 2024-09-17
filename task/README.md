# Assignment 1

For this practical exam, you will need to:

- Deploy a Pod based on the nginx image and verify that it has an IPv6 address allocated. Make sure the Pod is called my-nginx.
- Expose the nginx app with a NodePort Service. You can use the pre-populated YAML file service-challenge.yaml as a starting point. The file is located in the /exam/ folder.
- Verify with curl that access to nginx server over the Node IPv6 address is successful. Use TCP and port 80 to access this server.

## Solution

```bash
kubectl run my-nginx --image=nginx --restart=Never
kubectl describe pod my-nginx | grep IP

kubectl apply -f svc.yml

kubectl describe nodes
kubectl describe svc my-nginx-service

curl http://fd00:10:96::8b9b:30384

```
