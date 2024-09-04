// main template for cert-exoscale
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.cert_exoscale;

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
  '20_secret': secret,
}
