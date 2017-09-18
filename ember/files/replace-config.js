#!/usr/bin/env node

const fs = require('fs');
const newConfig = require('./config.json');

const filename = '/code/dist/index.html';
const page = fs.readFileSync(filename, {encoding: 'utf8'});
const rawConfig = /<meta name=".+?\/config\/environment" content="(.+?)" \/>/.exec(page)[1];
const config = JSON.parse(unescape(rawConfig));

// Deep merge, overrides config with newConfig recursively
(function deepMerge(newObj, oldObj) {
    for (const [key, val] of Object.entries(newObj)) {
        if (val && typeof val === 'object' && !Array.isArray(val)) {
            deepMerge(val, oldObj[key]);
        } else {
            oldObj[key] = newObj[key];
        }
    }
})(newConfig, config);

// Stringify and escape the new config
const updatedConfig = escape(JSON.stringify(config));
// Replace the old config on the page with the new config
const updatedPage = page.replace(rawConfig, updatedConfig);

// Write out the file
fs.writeFileSync(filename, updatedPage);
