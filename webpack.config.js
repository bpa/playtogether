var HtmlWebpackPlugin = require('html-webpack-plugin'),
    CopyWebpackPlugin = require("copy-webpack-plugin"),
    webpack = require("webpack"),
    path = require("path"),
    glob = require("glob"),
    copy = ['react/dist',
            'react-dom/dist',
            'pixi.js/bin',
            'jquery/dist',
            'bootstrap/dist'].map(function(d) {
        return glob.sync("node_modules/"+d+"/**/*.*");
    }).reduce(function(a,b){
        return a.concat(b)
    }).map(function(f) {
        var to = /(?:dist|bin)[/\\](([^/\\]+).*?\.([^.]+)(?:.map)?)$/.exec(f);
        var file = to[1];
        if (to[2] !== 'fonts' && to[2] !== to[3]) {
            file = path.join(to[3], file);
        }
        return {
            from: __dirname + '/' + f,
			to: file
        }
    });

module.exports = {
	context: __dirname + "/js",
    entry: './client.js',
	externals: {
		'pixi': 'PIXI',
		'react': 'React',
		'react-dom': 'ReactDOM'
	},
	devtool: 'source-map',
    module: {
        loaders: [
            {   test: /\.jsx?$/,
                include: [
                    __dirname + '/js',
                    __dirname + '/node_modules/react-bootstrap',
                ],
                loader: 'babel',
                query: {
                    presets: ['es2015', 'react']
                }
            },
        ]
    },
    output: {
        filename: "js/playtogether.js",
        path: __dirname + '/lib/Gamed/public',
        library: 'play',
    },
    plugins: [
        new HtmlWebpackPlugin({
            hash: true,
            inject: 'head',
            template: __dirname + '/index.tpl.html'
        }),
		new CopyWebpackPlugin(copy),
        //new webpack.optimize.UglifyJsPlugin({
        //    compress: {
        //        warnings: false,
        //    },
        //    output: {
        //        comments: false,
        //    },
        //}),
    ]
}
