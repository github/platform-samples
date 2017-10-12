const fs = require('fs')

fs.stat('dist/', function(err, stats) {
  if (err) {
    console.log('`dist/` folder does not exist. Creating it now.')
    return fs.mkdir('dist/', loadModules)
  }
  if (!stats.isDirectory()) {
    callback(new Error('`dist` is not a directory'))
  } else {
    console.log('`dist/` folder exists...deleting existing files')
    cleanDir()
    loadModules()
  }
})

const graphiqlModules = [
  'react/dist/react.min.js',
  'react-dom/dist/react-dom.min.js',
  'graphiql/graphiql.css',
  'graphiql/graphiql.min.js'
]

function cleanDir() {
  graphiqlModules.forEach(function(module) {
    let fileNameParts = module.split('/')
    let fileName = fileNameParts[fileNameParts.length - 1]
    deleteFile('dist/' + fileName)
  })

  // Delete Primer CSS
  deleteFile('dist/primer-css.css')
}

function loadModules() {
  graphiqlModules.forEach(function(module) {
    fs.stat('node_modules/' + module, function(err, stats) {
      if (err) {
        console.log('node_modules/' + module + ' does not exist. Exiting.')
        throw err
      }
    })
    let fileNameParts = module.split('/')
    let fileName = fileNameParts[fileNameParts.length - 1]
    copyFile('node_modules/' + module, 'dist/' + fileName)
  })

  // Copy Primer CSS
  copyFile('node_modules/primer-css/build/build.css', 'dist/primer-css.css')
}

function deleteFile(file) {
  return new Promise(function(resolve, reject) {
    fs.unlink(file, function(err) {
      if (err) {
        switch (err.errno) {
          case -2:
            console.log(file + ' does not exist. Skipping.')
            break;
          default:
            throw err
        }
      } else {
        console.log('Deleted ' + file)
        resolve()
      }

    })
  })
}

function copyFile(source, target) {
    return new Promise(function(resolve, reject) {
        var rd = fs.createReadStream(source);
        rd.on('error', rejectCleanup);
        var wr = fs.createWriteStream(target);
        wr.on('error', rejectCleanup);
        function rejectCleanup(err) {
            rd.destroy();
            wr.end();
            reject(err);
        }
        wr.on('finish', resolve);
        rd.pipe(wr);
    });
}
