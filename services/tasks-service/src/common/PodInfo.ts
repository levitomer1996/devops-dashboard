export default {
  podName: process.env.POD_NAME ?? process.env.HOSTNAME ?? 'unknown',
  namespace: process.env.POD_NAMESPACE ?? 'unknown',
  nodeName: process.env.NODE_NAME ?? 'unknown',
  podIP: process.env.POD_IP ?? 'unknown',
};
