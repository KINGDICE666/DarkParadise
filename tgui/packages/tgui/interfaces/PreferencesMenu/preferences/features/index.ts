import type { Feature } from './base';

export const features: Record<string, Feature<unknown>> = {};

const requireFeature = require.context('./', true, /.tsx$/);

for (const key of requireFeature.keys()) {
  if (key === 'index' || key === 'base') {
    continue;
  }

  for (const [featureKey, feature] of Object.entries(requireFeature(key))) {
    features[featureKey] = feature as Feature<unknown>;
  }
}
