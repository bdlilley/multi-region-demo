Load testing

https://k6.io/blog/running-distributed-tests-on-k8s/

kubectl apply  -n default --context mgmt-1 -f -<<EOT
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: k6-demo
spec:
  parallelism: 2
  script:
    configMap:
      name: demo-stress-test
      file: k6-test-script.js
EOT


Promql query

sum without (workload_id, source_principal) (rate(istio_requests_total{destination_workload_id="demo.demo.workload-1", connection_security_policy="mutual_tls", response_code="200"}[5m]))

sum without (workload_id, source_principal) (rate(istio_requests_total{destination_workload_id="demo.demo.workload-1", connection_security_policy="mutual_tls", response_code!="200"}[5m])) OR on() vector(0)