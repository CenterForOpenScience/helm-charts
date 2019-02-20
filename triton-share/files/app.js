const http = require('http');
const https = require('https');

const {
    SHARE_HOST = 'staging-share.osf.io',
    PORT = '9000',
} = process.env;

function httpsRequest(options) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, res => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve({ ...res, body }));
        });

        req.on('error', reject);
        req.end();
    });
}

async function getAgent({ key }) {
    const {
        body: { _source, doc_count, awards }
    } = await httpsRequest({
        hostname: SHARE_HOST,
        path: `/api/v2/search/agents/${key}`,
    });

    return {
        name: '',
        sources: [],
        location: '',
        identifiers: [],
        type: '',
        types: [],
        ..._source,
        id: key,
        number: doc_count,
        awards,
    };
}

function requestListener(request, response) {
    if (request.url === '/healthz') {
        response.writeHead(200);
        return response.end();
    }

    if (request.method === 'GET') {
        return response.end(`It Works!! Path Hit: ${request.url}`);
    }

    let body = '';

    request.on('data', data => body += data);

    request.on('end', async () => {
        let agentIds;

        try {
            agentIds = JSON.parse(body);
        } catch (e) {
            response.writeHead(400);
            return response.end('Unable to parse request body');
        }

        const responseObject = await Promise.all(agentIds.map(getAgent));

        response.end(JSON.stringify(responseObject));
    });
}

http.createServer(requestListener)
    .listen(PORT, () => console.info(`Server listening on: http://localhost:${PORT}`));
