#!/usr/bin/env node

const fs = require('fs');
const { MULTI_CONFIG = 'false' } = process.env;


function deepMerge(newObj, oldObj) {
    for (const [key, val] of Object.entries(newObj)) {
        if (oldObj[key] && val && typeof val === 'object' && !Array.isArray(val)) {
            deepMerge(val, oldObj[key]);
            continue;
        }

        oldObj[key] = newObj[key];
    }
}

function updateConfig(page, metaName, newConfig) {
    const rgxStr = `<meta name="(${metaName})" content="(.+?)"\\W*\\/?>`;

    return page.replace(new RegExp(rgxStr), (_, name, rawConfig) => {
        const config = JSON.parse(unescape(rawConfig));

        // Deep merge, overrides config with newConfig recursively
        deepMerge(newConfig, config);
    
        // Stringify and escape the new config
        const updatedConfig = escape(JSON.stringify(config));

        return `<meta name="${name}" content="${updatedConfig}" />`;
    });
}

const deserializedConfig = require('./config.json');
const newConfigs = MULTI_CONFIG === 'true' ? deserializedConfig : { '.+?/config/environment':  deserializedConfig };
const filename = '/code/dist/index.html';
const page = fs.readFileSync(filename, {encoding: 'utf8'});
const updatedPage = Object.entries(newConfigs)
    .reduce((acc, [key, val]) => updateConfig(acc, key.replace('/', '\\/'), val), page);

// Write out the file
fs.writeFileSync(filename, updatedPage);
