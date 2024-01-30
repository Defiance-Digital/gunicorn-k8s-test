# gunicorn-k8s-test

There is a dearth of information on how to run a Flask/Django app on Kubernetes using Gunicorn. What information is available is often conflicting and confusing. Based on issues I've seen with my customers over the last year, this repository aims to test the exact impact of running multiple gunicorn workers in a single Kubernetes pod.

The code is written to work on a local Docker Desktop Kubernetes cluster. It's unlikely I will generalize it to work on other Kubernetes clusters, but feel free to fork and modify it to your needs. Pull requests with additional functionality are very welcome!

tl;dr The conventional wisdom to use multiple workers in a containerized instance of Flask/Django/anything that is served with gunicorn is incorrect - you should only use one worker per container, otherwise you're not properly using the resources allocated to your application. Using multiple workers per container also runs the risk of OOM SIGKILLs without logging, making diagnosis of issues much more difficult than it would be otherwise.

## Execution

Install Docker Desktop and enable Kubernetes. Then run:

```bash
bash run-test.sh | tee results.txt
```

This will perform the test with 2 gunicorn workers in a pod. In theory, this should give each worker half of the available pod memory, or 500MB. The output of `results.txt` should validate this theory - after approximately 5 seconds, the workers should start to fail with memory errors.

To perform the test again with 1 gunicorn worker in a pod, edit `value: "2"` in `manifests/python-app.yaml` to be `value: "1"`, then run:

```bash
bash run-test.sh | tee results-single.txt
```

You should see it takes about 10 seconds to fail with memory errors instead of 5. This is because the single worker is able to use the full 1GB of memory available to the pod.
