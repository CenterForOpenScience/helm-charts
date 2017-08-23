#!/usr/bin/env node
var prerender = require('./lib');

var server = prerender({
    workers: process.env.PRERENDER_NUM_WORKERS || 1,
    iterations: process.env.PRERENDER_NUM_ITERATIONS || 40,
    softIterations: process.env.PRERENDER_NUM_SOFT_ITERATIONS || 30
});

server.use(prerender.sendPrerenderHeader());
// server.use(prerender.basicAuth());
server.use(prerender.whitelist());
// server.use(prerender.blacklist());
// server.use(prerender.logger());
server.use(prerender.removeScriptTags());
server.use(prerender.httpHeaders());


server.use(require('prerender-redis-cache'));
// process.env.PAGE_TTL = 3600 * 24 * 5; // change to 0 if you want all time cache
// server.use(prerender.inMemoryHtmlCache());
// server.use(prerender.s3HtmlCache());

var throttleToken = process.env.THROTTLE_TOKEN;

server.use({
    onPhantomPageCreate: function(phantom, req, res, next) {
        req.prerender.page.run(function(resolve) {
            var customHeaders = this.customHeaders;
            customHeaders['X-THROTTLE-TOKEN'] = throttleToken;
            this.customHeaders = customHeaders;
            resolve();
        }).then(function() {
            next();
        }).catch(function() {
            next();
        });
    }
});

server.start();