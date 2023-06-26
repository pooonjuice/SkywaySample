const { SkyWayAuthToken, uuidV4 } = require('@skyway-sdk/token');
const token = new SkyWayAuthToken({
  jti: uuidV4(),
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24,
  scope: {
    app: {
      id: '3ebfda58-23cd-4118-a59a-aaf38c9ffc21',
      turn: true,
      actions: ['read'],
      channels: [
        {
          id: '*',
          name: '*',
          actions: ['write'],
          members: [
            {
              id: '*',
              name: '*',
              actions: ['write'],
              publication: {
                actions: ['write'],
              },
              subscription: {
                actions: ['write'],
              },
            },
          ],
          sfuBots: [
            {
              actions: ['write'],
              forwardings: [
                {
                  actions: ['write'],
                },
              ],
            },
          ],
        },
      ],
    },
  },
}).encode('M+qENN5LOuBaLcTOOk6ha7E3X/VMj21LxpzHUvbyiEE=');
console.log(token);