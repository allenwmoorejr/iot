# Homebridge backup scheduling failures

This page documents how to troubleshoot the repeated `FailedScheduling` warnings that show up for the `homebridge-backup` CronJob.

## Symptoms

`kubectl events -n suite` prints output similar to:

```
Warning  FailedScheduling  Pod/homebridge-backup-29337612-7jz5g  0/5 nodes are available: persistentvolumeclaim "homebridge-data" is being deleted. preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling.
```

The cluster keeps creating replacement pods (for example `homebridge-backup-29339052-smj58`) but none of them can schedule while the message continues to reference the `homebridge-data` PersistentVolumeClaim (PVC).

## Root cause

The CronJob template mounts the `homebridge-data` PVC so that it can take a tarball of the Homebridge configuration. If the PVC is in the `Terminating` state (for example, because a previous restore deleted it but the object is still finalizing), Kubernetes will block all new pods that reference it.

Because the CronJob keeps retrying on its schedule, you will see thousands of `FailedScheduling` events.

## Resolution

1. Verify the PVC status:
   ```bash
   kubectl -n suite get pvc homebridge-data -o yaml
   ```
2. If the PVC is stuck terminating, clear any finalizers and delete it:
   ```bash
   kubectl -n suite patch pvc homebridge-data -p '{"metadata":{"finalizers":null}}' --type=merge
   kubectl -n suite delete pvc homebridge-data
   ```
3. Recreate the PVC:
   ```bash
   kubectl apply -f 20-storage/homebridge-pvcs.yaml
   ```
4. Re-run the backup job manually to confirm it schedules:
   ```bash
   kubectl -n suite create job --from=cronjob/homebridge-backup homebridge-backup-now
   ```

While the PVC is unavailable the CronJob will continue to log `FailedScheduling` events. Restoring the PVC clears the errors and allows the job to resume as expected.

## Related event: `micro-cam-relay` init container back-off

The same `kubectl events -n suite` output may also show the `micro-cam-relay` Deployment crashing its `init-fifo` init container:

```
Warning  BackOff  Pod/micro-cam-relay-588ff897bb-rkf64  Back-off restarting failed container init-fifo in pod micro-cam-relay-588ff897bb-rkf64_suite(...)
```

This usually means the FIFO setup script exited non-zero. Collect the init container logs and re-run it locally to verify configuration:

```bash
kubectl -n suite logs pod/micro-cam-relay-588ff897bb-rkf64 -c init-fifo
kubectl -n suite describe pod micro-cam-relay-588ff897bb-rkf64
```

Fix the configuration (for example, missing hostPath or permissions) and then delete the failing pod so the Deployment recreates it.
