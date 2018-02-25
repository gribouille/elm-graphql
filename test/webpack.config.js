'use strict';

const webpack           = require('webpack');
const path              = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const port              = 8080;
const host              = 'localhost';
const entryPath         = path.join(__dirname, 'index.js');



const htmlPlugin = new HtmlWebpackPlugin({
    template: 'index.html',
    inject: 'body',
    filename: 'index.html',
    title: "gribouille/elm-graphql examples",
    author: 'Gribouille'
});

module.exports = {
  resolve: {
      extensions: ['.js', '.elm'],
      modules: ['node_modules']
  },
  entry: [
      `webpack-dev-server/client?http://${host}:${port}`,
      entryPath
  ],
  devServer: {
      // serve index.html in place of 404 responses
      historyApiFallback: true,
      contentBase: [
          '../src',
          '../node_modules',
          './src',
          './'
      ],
      hot: true,
      proxy: {
        '/api': {
          target: 'http://127.0.0.1:4000/',
          pathRewrite: {
            '^/api' : ''
          },
          secure: false
        }
      }
  },
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: 'elm-webpack-loader',
            options: {
              verbose: true,
              warn: true,
              debug: true
            }
          }
        ]
      }
    ]
  },
  plugins: [htmlPlugin]
}
