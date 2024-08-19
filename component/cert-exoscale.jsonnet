// main template for cm-hetznercloud
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.cert_exoscale;
local paramsCertManager = inv.parameters.cert_manager;


local certExoscale = com.Kustomization(
  'https://github.com/exoscale/cert-manager-webhook-exoscale//deploy/exoscale-webhook-kustomize',
  params.manifestVersion,
  {
    'exoscale/cert-manager-webhook-exoscale': {
      newTag: params.images.webhook.tag,
      newName: '%(registry)s/%(repository)s' % params.images.webhook,
    },
  },
  {
    patches: [
      {
        target: {
          kind: 'Deployment',
          name: 'cert-manager-webhook-exoscale',
          namespace: 'cert-manager',
        },
        patch: |||
          - op: add
            path: /spec/template/spec/containers/0/args/-
            value: --secure-port=8443
          - op: replace
            path: /spec/template/spec/containers/0/ports/0/containerPort
            value: 8443
          - op: replace
            path: /spec/replicas
            value: 1
        |||,
      },
      {
        target: {
          kind: 'ClusterRoleBinding',
          name: 'cert-manager-webhook-exoscale:domain-solver',
        },
        patch: |||
          - op: replace
            path: /subjects/0/namespace
            value: %(namespace)s
        ||| % { namespace: paramsCertManager.namespace },
      },
      {
        target: {
          kind: 'APIService',
          name: 'v1alpha1.acme.exoscale.com',
        },
        patch: |||
          - op: replace
            path: /metadata/annotations
            value:
              cert-manager.io/inject-ca-from: %(namespace)s/cert-manager-webhook-exoscale-webhook-tls
        ||| % { namespace: params.namespace },
      },
      {
        target: {
          kind: 'Certificate',
          name: 'cert-manager-webhook-exoscale-ca',
          namespace: 'cert-manager',
        },
        patch: |||
          - op: replace
            path: /spec/commonName
            value: ca.exoscale-webhook.%(namespace)s
          - op: replace
            path: /spec/duration
            value: 43800h0m0s
        ||| % { namespace: params.namespace },
      },
      {
        target: {
          kind: 'Certificate',
          name: 'cert-manager-webhook-exoscale-webhook-tls',
          namespace: 'cert-manager',
        },
        patch: |||
          - op: replace
            path: /spec/dnsNames
            value:
              - cert-manager-webhook-exoscale
              - cert-manager-webhook-exoscale.%(namespace)s
              - cert-manager-webhook-exoscale.%(namespace)s.svc
          - op: replace
            path: /spec/duration
            value: 8760h0m0s
        ||| % { namespace: params.namespace },
      },
    ],
  } + com.makeMergeable(params.kustomizeInput),
) {};

certExoscale
