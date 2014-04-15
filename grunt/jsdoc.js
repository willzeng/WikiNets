module.exports = {
    dist: {
        src    : [
            'README.md',
            'static/core/*.js'
        ],
        jsdoc  : 'node_modules/.bin/jsdoc',
        options: {
            configure  : './conf.json',
            destination: 'docs/api'
        }
    }
};
