# CRDs source directory

CRDs from that folder match exactly the same state of CRDs from the `templates` folder, which cert manager allows to apply with Helm, but in general it is not recommended to deploy CRDs with helm, so use `kubectl apply -f cert-manager/crds`.