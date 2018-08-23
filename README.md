# Kubernetes Event Logger

> Simple container that runs in kube-system namespace and streams Kubernetes
events (via Kubernetes API) to stdout.


## Contents

*   [Kubernetes Event Logger Vs Heapster Eventer](#kubernetes-event-logger-vs-heapster-eventer)
*   [Usage](#uasge)
*   [Files](#files)


---


## Kubernetes Event Logger Vs Heapster Eventer

Heapster-Eventer is a version of Heapster that can be run in your cluster to gather
Kubernetes events. It can be configured to store those events in a
[sink](https://github.com/kubernetes/heapster/blob/master/docs/sink-configuration.md#elasticsearch),
such as Elasticsearch. [This post](https://www.aerisweather.com/blog/monitoring-kubernetes-elasticsearch/)
provides a great example of how this can be done for Heapster metrics but it can adapted to
work for Heapster Eventer.

While Heapster-Eventer may make sense for some deployments, Kubernetes Event Logger
may be a better solution for your deployments. Since we already utilize the
Filebeat-->Logstash-->Elasticsearch workflow for all of our other Kubernetes cluster logs,
it makes sense to use that same workflow for the Kubernetes events. All we
have to do is deploy a Kubernetes Event Logger pod, use Filebeat to collect all of
the Kubernetes events the pod streams to it's console, and ship those off to Logstash
where we will write parsers alongside all of our other log parsers before forwarding
to Elasticsearch. Another reason that using Kubernetes Event Logger might be better
than Heapster-Eventer is that, as observed in testing, when configured to use the
Elasticsearch sink, if Elasticsearch goes down for any reason or the connection
is lost, Heapster-Eventer seems to take much too long to recover the connection,
and all of those events that Heapster attempted to send to ES when the connection
was lost never make it to ES. This is unnacceptable for our monitoring requirements.


---


## Usage

0. (Optional) Add an index mapping to Elasticsearch so you have mappings for Kubernetes events:
```bash
curl -XPUT http://elasticsearch-url:9200/_template/kubernetes-event-mappings?pretty -d @es-kubernetes-event-template.json
```

1. Deploy pod using:
```
kubectl --context=<YOUR_CONTEXT> -n kube-system apply -f files/deployment.yaml
```

2. Scrape the pod's logs using `Filebeat` ---> `Logstash` ---> `Elasticsearch`.

#### Example Log Output

This event logger pod will stream Kubernetes events from the Kubernetes API to
the pods stdout logs. Below is an example of what you can expect to see in the
pod's logs:

```
{"type":"ADDED","object":{"kind":"Event","apiVersion":"v1","metadata":{"name":"test-service-66c8db4d94-fkmsz.1517f42c3d6cd92d","namespace":"test1","selfLink":"/api/v1/namespaces/test1/events/test-service-66c8db4d94-fkmsz.1517f42c3d6cd92d","uid":"cc70afee-1db3-11e8-814d-005056946849","resourceVersion":"14188603","creationTimestamp":"2018-03-02T00:51:10Z"},"involvedObject":{"kind":"Pod","namespace":"test1","name":"test-service-66c8db4d94-fkmsz","uid":"cae9efdb-1db3-11e8-ba85-005056944e80","apiVersion":"v1","resourceVersion":"14188588","fieldPath":"spec.containers{test-service}"},"reason":"Pulled","message":"Successfully pulled image \"localhost:4567/gcosta/test-service:develop\"","source":{"component":"kubelet","host":"prod-1-kubeworker02.dc1.ec.loc"},"firstTimestamp":"2018-03-02T00:51:10Z","lastTimestamp":"2018-03-02T00:51:10Z","count":1,"type":"Normal"}}
{"type":"ADDED","object":{"kind":"Event","apiVersion":"v1","metadata":{"name":"test-service-66c8db4d94-fkmsz.1517f42c518fcce9","namespace":"test1","selfLink":"/api/v1/namespaces/test1/events/test-service-66c8db4d94-fkmsz.1517f42c518fcce9","uid":"cca444fe-1db3-11e8-814d-005056946849","resourceVersion":"14188605","creationTimestamp":"2018-03-02T00:51:10Z"},"involvedObject":{"kind":"Pod","namespace":"test1","name":"test-service-66c8db4d94-fkmsz","uid":"cae9efdb-1db3-11e8-ba85-005056944e80","apiVersion":"v1","resourceVersion":"14188588","fieldPath":"spec.containers{test-service}"},"reason":"Created","message":"Created container","source":{"component":"kubelet","host":"prod-1-kubeworker02.dc1.ec.loc"},"firstTimestamp":"2018-03-02T00:51:10Z","lastTimestamp":"2018-03-02T00:51:10Z","count":1,"type":"Normal"}}
{"type":"ADDED","object":{"kind":"Event","apiVersion":"v1","metadata":{"name":"test-service-66c8db4d94-fkmsz.1517f42c6930c531","namespace":"test1","selfLink":"/api/v1/namespaces/test1/events/test-service-66c8db4d94-fkmsz.1517f42c6930c531","uid":"cce0b3e7-1db3-11e8-814d-005056946849","resourceVersion":"14188607","creationTimestamp":"2018-03-02T00:51:10Z"},"involvedObject":{"kind":"Pod","namespace":"test1","name":"test-service-66c8db4d94-fkmsz","uid":"cae9efdb-1db3-11e8-ba85-005056944e80","apiVersion":"v1","resourceVersion":"14188588","fieldPath":"spec.containers{test-service}"},"reason":"Started","message":"Started container","source":{"component":"kubelet","host":"prod-1-kubeworker02.dc1.ec.loc"},"firstTimestamp":"2018-03-02T00:51:10Z","lastTimestamp":"2018-03-02T00:51:10Z","count":1,"type":"Normal"}}
```

_Formatted version of above logs_:

```json
{
   "type":"ADDED",
   "object":{
      "kind":"Event",
      "apiVersion":"v1",
      "metadata":{
         "name":"test-service-66c8db4d94-fkmsz.1517f42c3d6cd92d",
         "namespace":"test1",
         "selfLink":"/api/v1/namespaces/test1/events/test-service-66c8db4d94-fkmsz.1517f42c3d6cd92d",
         "uid":"cc70afee-1db3-11e8-814d-005056946849",
         "resourceVersion":"14188603",
         "creationTimestamp":"2018-03-02T00:51:10Z"
      },
      "involvedObject":{
         "kind":"Pod",
         "namespace":"test1",
         "name":"test-service-66c8db4d94-fkmsz",
         "uid":"cae9efdb-1db3-11e8-ba85-005056944e80",
         "apiVersion":"v1",
         "resourceVersion":"14188588",
         "fieldPath":"spec.containers{test-service}"
      },
      "reason":"Pulled",
      "message":"Successfully pulled image \"localhost:4567/gcosta/test-service:develop\"",
      "source":{
         "component":"kubelet",
         "host":"prod-1-kubeworker02.dc1.ec.loc"
      },
      "firstTimestamp":"2018-03-02T00:51:10Z",
      "lastTimestamp":"2018-03-02T00:51:10Z",
      "count":1,
      "type":"Normal"
   }
}
{
   "type":"ADDED",
   "object":{
      "kind":"Event",
      "apiVersion":"v1",
      "metadata":{
         "name":"test-service-66c8db4d94-fkmsz.1517f42c518fcce9",
         "namespace":"test1",
         "selfLink":"/api/v1/namespaces/test1/events/test-service-66c8db4d94-fkmsz.1517f42c518fcce9",
         "uid":"cca444fe-1db3-11e8-814d-005056946849",
         "resourceVersion":"14188605",
         "creationTimestamp":"2018-03-02T00:51:10Z"
      },
      "involvedObject":{
         "kind":"Pod",
         "namespace":"test1",
         "name":"test-service-66c8db4d94-fkmsz",
         "uid":"cae9efdb-1db3-11e8-ba85-005056944e80",
         "apiVersion":"v1",
         "resourceVersion":"14188588",
         "fieldPath":"spec.containers{test-service}"
      },
      "reason":"Created",
      "message":"Created container",
      "source":{
         "component":"kubelet",
         "host":"prod-1-kubeworker02.dc1.ec.loc"
      },
      "firstTimestamp":"2018-03-02T00:51:10Z",
      "lastTimestamp":"2018-03-02T00:51:10Z",
      "count":1,
      "type":"Normal"
   }
}
{
   "type":"ADDED",
   "object":{
      "kind":"Event",
      "apiVersion":"v1",
      "metadata":{
         "name":"test-service-66c8db4d94-fkmsz.1517f42c6930c531",
         "namespace":"test1",
         "selfLink":"/api/v1/namespaces/test1/events/test-service-66c8db4d94-fkmsz.1517f42c6930c531",
         "uid":"cce0b3e7-1db3-11e8-814d-005056946849",
         "resourceVersion":"14188607",
         "creationTimestamp":"2018-03-02T00:51:10Z"
      },
      "involvedObject":{
         "kind":"Pod",
         "namespace":"test1",
         "name":"test-service-66c8db4d94-fkmsz",
         "uid":"cae9efdb-1db3-11e8-ba85-005056944e80",
         "apiVersion":"v1",
         "resourceVersion":"14188588",
         "fieldPath":"spec.containers{test-service}"
      },
      "reason":"Started",
      "message":"Started container",
      "source":{
         "component":"kubelet",
         "host":"prod-1-kubeworker02.dc1.ec.loc"
      },
      "firstTimestamp":"2018-03-02T00:51:10Z",
      "lastTimestamp":"2018-03-02T00:51:10Z",
      "count":1,
      "type":"Normal"
   }
}
```


---


## Files

The `/files` folder contains useful files to help you with Kubernetes Event logging.

* `get-events.sh`

  Main file that is run in the Dockerfile to stream the Kubernetes events.

* `deployment.yaml`

  Kubernetes Deployment file for Kubernetes Event Logger image.

* `es-kubernetes-event-template.json`

  Elasticsearch index template to be used to map Kubernetes Events streamed by
  this pod to searchable ES fields.

* `logstash-parsers.conf`

  An example Logstash parser config. (**See near bottom of config for
  Kubernetes Events parsing logic**)
