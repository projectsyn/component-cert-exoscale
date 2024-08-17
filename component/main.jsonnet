// main template for cert-exoscale
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.cert_exoscale;
local isOpenshift = std.member([ 'openshift', 'oke' ], inv.parameters.facts.distribution);

local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/name': params.namespace,
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    },
  },
};

local secret = kube.Secret('exoscale-secret') {
  metadata+: {
    namespace: params.namespace,
  },
  stringData: {
    EXOSCALE_API_KEY: params.secret.accessKey,
    EXOSCALE_API_SECRET: params.secret.secretKey,
  },
};

// Define outputs below
{
  '00_namespace': namespace,
  '20_secret': secret,
}
