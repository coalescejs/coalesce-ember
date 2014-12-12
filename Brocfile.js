var fs = require('fs');
var traceur = require('broccoli-traceur');
var pickFiles = require('broccoli-static-compiler');
var mergeTrees = require('broccoli-merge-trees');
var writeFile = require('broccoli-file-creator');
var moveFile = require('broccoli-file-mover');
var concat = require('broccoli-concat');
var uglify = require('broccoli-uglify-js');
var removeFile = require('broccoli-file-remover');
var defeatureify = require('broccoli-defeatureify');
var emberScript = require('broccoli-ember-script');
var replace = require('broccoli-replace');
var yuidocCompiler = require('broccoli-yuidoc');

var calculateVersion = require('./lib/calculate-version');

var licenseJs = fs.readFileSync('./generators/license.js').toString();

var devAmd = (function() {
  var tree = pickFiles('src', {
    srcDir: '/',
    destDir: 'coalesce-ember'
  });
  var vendoredPackage = moveFile(tree, {
    srcFile: 'coalesce-ember/main.js',
    destFile: '/coalesce-ember.js'
  });

  tree = mergeTrees([tree, vendoredPackage]);
  tree = removeFile(tree,  {
    files: ['coalesce-ember/main.js']
  });
  var transpiled = traceur(tree, {
    moduleName: true,
    modules: 'amd',
    annotations: true
  });
  return concat(transpiled, {
    inputFiles: ['**/*.js'],
    outputFile: '/coalesce-ember.amd.js'
  });
})();

var prodAmd = (function() {

  var tree = moveFile(devAmd, {
    srcFile: 'coalesce-ember.amd.js',
    destFile: '/coalesce-ember.prod.amd.js'
  });

  tree = defeatureify(tree, {
    enabled: true,
    enableStripDebug: true,
    debugStatements: [
      "console.assert"
    ]
  });

  return tree;

})();

var vendor = mergeTrees(['node_modules/traceur/bin', 'bower_components']);

var devStandalone = (function() {
  var iifeStart = writeFile('iife-start', '(function() {');
  var iifeStop  = writeFile('iife-stop', '})();');
  var bootstrap = writeFile('bootstrap', 'this.Coalesce = requireModule("coalesce-ember")["default"];\n');

  var trees = [vendor, iifeStart, iifeStop, bootstrap, devAmd];

  return concat(mergeTrees(trees), {
    inputFiles: [
      'iife-start',
      'loader/loader.js',
      'traceur-runtime.js',
      'coalesce/coalesce.amd.js',
      'coalesce-ember.amd.js',
      'bootstrap',
      'iife-stop'
    ],
    outputFile: '/coalesce-ember.standalone.js'
  });
})();

var prodStandalone = (function() {
  var iifeStart = writeFile('iife-start', '(function() {');
  var iifeStop  = writeFile('iife-stop', '})();');
  var bootstrap = writeFile('bootstrap', 'this.Coalesce = requireModule("coalesce-ember")["default"];\n');

  var trees = [vendor, iifeStart, iifeStop, bootstrap, prodAmd];

  return concat(mergeTrees(trees), {
    inputFiles: [
      'iife-start',
      'loader/loader.js',
      'traceur-runtime.js',
      'coalesce/coalesce.prod.amd.js',
      'coalesce-ember.prod.amd.js',
      'bootstrap',
      'iife-stop'
    ],
    outputFile: '/coalesce-ember.prod.standalone.js'
  });
})();

var minStandalone = (function() {

  var tree = moveFile(prodStandalone, {
    srcFile: 'coalesce-ember.prod.standalone.js',
    destFile: '/coalesce-ember.prod.standalone.min.js'
  });
  return uglify(tree);

})();

var testTree = (function() {
  var testAmd = (function() {
    var tree = pickFiles('test', {
      srcDir: '/',
      destDir: 'coalesce-ember-test'
    });

    tree = emberScript(tree, {
      bare: true
    });

    var transpiled = traceur(tree, {
      moduleName: true,
      modules: 'amd'
    });
    return concat(transpiled, {
      inputFiles: ['**/*.js'],
      outputFile: '/coalesce-ember-test.amd.js'
    });
  })();
  
  var testVendorJs = concat(vendor, {
    inputFiles: [
      'mocha/mocha.js',
      'chai/chai.js',
      'sinonjs/sinon.js',
      'localforage/dist/localforage.js',
      'jquery/dist/jquery.js',
      'handlebars/handlebars.runtime.js',
      'ember/dist/ember.js',
      'ember-mocha-adapter/adapter.js',
      'lodash/dist/lodash.js',
      'loader/loader.js',
      'traceur-runtime.js',
      'coalesce/coalesce.amd.js'
    ],
    outputFile: '/vendor.js'
  });
  
  var testVendorCss = pickFiles(vendor, {
    srcDir: '/mocha',
    files: ['mocha.css'],
    destDir: '/'
  });
  
  var trees = mergeTrees([testVendorJs, testAmd, devAmd, 'test', testVendorCss]);
  return pickFiles(trees, {
    srcDir: '/',
    files: [
      'vendor.js',
      'mocha.css',
      'coalesce-ember.amd.js',
      'coalesce-ember-test.amd.js',
      'index.html'
    ],
    destDir: 'test'
  });
  
})();


var bowerJSON = writeFile('bower.json', JSON.stringify({
  name: 'coalesce-ember',
  version: 'VERSION_STRING_PLACEHOLDER',
  license: "MIT",
  main: 'coalesce-ember.js',
  ignore: ['docs', 'test', 'testem.js'],
  keywords: [
    "coalesce-ember",
    "orm",
    "persistence",
    "data",
    "sync"
  ]
}, null, 2));

distTree = mergeTrees([bowerJSON, devAmd, prodAmd, devStandalone, prodStandalone, minStandalone]);
distTree = replace(distTree, {
  files: [ '**/*.js' ],
  patterns: [
    { match: /^/, replacement: licenseJs }
  ]
});
distTree = replace(distTree, {
  files: [ '**/*' ],
  patterns: [
    { match: /VERSION_STRING_PLACEHOLDER/g, replacement: calculateVersion }
  ]
});

var docs = yuidocCompiler('src', {
  srcDir: '/',
  destDir: 'docs'
});

var testemDummy = writeFile('testem.js', '');

module.exports = mergeTrees([docs, distTree, testTree, testemDummy]);
