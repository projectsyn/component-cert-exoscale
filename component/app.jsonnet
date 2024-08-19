local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.cert_exoscale;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('cert-exoscale', params.namespace) {
  spec+: {
    syncPolicy+: {
      syncOptions+: [
        'ServerSideApply=true',
      ],
    },
  },
};

{
  'cert-exoscale': app,
}
