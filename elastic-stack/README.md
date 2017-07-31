# Installation

```bash
helm dep up ./elastic-stack
helm install ./elastic-stack -f /path/to/values.yaml
```

# X-Pack

## Getting the license
Sign-up for an [x-pack license](https://register.elastic.co/)

## Installation
[Installation Guide](https://www.elastic.co/guide/en/x-pack/current/installing-license.html)

### TL;DR
Run download the license and run these commands

#### Port forward to the elasticsearch client
```bash
kubectl port-forward <.Release.Name>-elasticsearch-client-<pod> 9200 &
```
#### Put the license file
```bash
curl -XPUT -u elastic:changeme 'http://localhost:9200/_xpack/license?acknowledge=true' -H "Content-Type: application/json" -d @license.json
```
```JSON
{
  "acknowledged": true,
  "license_status": "valid"
}
```
#### Check that the license is active
```bash
curl -XGET -u elastic:changeme 'http://localhost:9200/_xpack/license'
```
```JSON
{
  "license" : {
    "status" : "active",
    "uid" : "deadbeef-f33d-b33f-a11f-000011112222",
    "type" : "basic",
    "issue_date" : "2017-06-28T00:00:00.000Z",
    "issue_date_in_millis" : 1498608000000,
    "expiry_date" : "2018-06-28T23:59:59.999Z",
    "expiry_date_in_millis" : 1530230399999,
    "max_nodes" : 100,
    "issued_to" : "Someone",
    "issuer" : "Web Form",
    "start_date_in_millis" : 1498608000000
  }
}
```