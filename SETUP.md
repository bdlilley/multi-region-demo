Load testing

https://k6.io/blog/running-distributed-tests-on-k8s/

kubectl apply  -n default --context mgmt-1 -f -<<EOT
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: k6-demo
spec:
  parallelism: 1
  arguments: --out json --dns ttl=0,select=random,policy=onlyIPv4
  script:
    configMap:
      name: demo-stress-test
      file: k6-test-script.js
EOT

kubectl apply  -n default --context mgmt-2 -f -<<EOT
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: k6-demo
spec:
  parallelism: 1
  arguments: --out json --dns ttl=0,select=random,policy=onlyIPv4
  script:
    configMap:
      name: demo-stress-test
      file: k6-test-script.js
EOT

kubectl delete k6 --all -A --context mgmt-1
kubectl delete k6 --all -A --context mgmt-2


stern k6-demo-1 --context mgmt-1 --output json | jq '.message | fromjson | select(.data.tags.status != null) | .data.time + "    " + .data.tags.status'

stern k6-demo-1 --context mgmt-2 --output json | jq '.message | fromjson | select(.data.tags.status != null) | .data.time + "    " + .data.tags.status'



Promql query


sum without (workload_id, source_principal) (rate(istio_requests_total{destination_workload_id="demo.demo.workload-1", connection_security_policy="mutual_tls", response_code="200"}[5m]))

sum without (workload_id, source_principal) (rate(istio_requests_total{destination_workload_id="demo.demo.workload-2", connection_security_policy="mutual_tls", response_code="200"}[5m]))

sum by (istio_io_rev) (rate(istio_requests_total{response_code!="200"}[5m]))