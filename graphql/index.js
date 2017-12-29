#!/usr/bin/env node
'use strict';
const fs = require('fs');
const request = require('request');
const queryObj = {};
const program = require('commander');
const variablesRegex = /variables([\s\S]*)}/gm;

program
    .version('0.0.1')
    .usage('<file> <token>')
    .arguments('<file> <token>')
    .action(function(file, token){
        console.log("Running query: " + file);
        runQuery(file, token);
    })
    .description('Execute specified GraphQL query');

program.parse(process.argv);

if (!process.argv.slice(2).length)
{
    console.log("Missing query file and/or token argument");
    process.exitCode = 1;
}

function runQuery(file, token) {
    
    try {
        var queryText = fs.readFileSync(process.argv[2], "utf8");
    }
    catch (e) {
        console.log("Problem opening query file: " + e.message);
        process.exit(1);
    }

    //If there is a variables section, extract the values and add them to the query JSON object.  
    queryObj.variables = variablesRegex.test(queryText) ? JSON.parse(queryText.match(variablesRegex)[0].split("variables ")[1]) : {}
    //Remove the variables section from the query text, whether it exists or not
    queryObj.query = queryText.replace(variablesRegex, '');

    request({
        url: "https://api.github.com/graphql"
        , method: "POST"
        , headers: {
            'authorization': 'bearer ' + token
            , 'content-type': 'application/json'
            , 'user-agent': 'platform-samples'
        }
        , json: true
        , body: queryObj
    }, function (error, response, body) {
        console.log(JSON.stringify(body, null, 2));
    });
};