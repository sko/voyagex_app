# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile =
  [
    '*.png',
    '*.gif',
    '*.jpg',
    '*.mp3',
    '*.js',
    'application.css',
    'application.mobile.css',
    'main.css',
    'main.mobile.css',
    './comm/application.css',
    'swiper.css',
    'jquery*.css',
    'leaflet*.css',
    '_bootstrap-compass.css',
    '_bootstrap-mincer.css',
    '_bootstrap-sprockets.css',
    './bootstrap/_variables.css',
    '_bootstrap.css',
    './bootstrap/*.css'
  ]
