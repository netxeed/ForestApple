[app]
title = ForestApple
package.name = forestapple
package.domain = org.forestapple
source.dir = .
source.include_exts = py,png,json,txt
version = 0.1.0
requirements = python3,pygame-ce
orientation = landscape
fullscreen = 1
icon.filename = %(source.dir)s/assets/icon.png
android.permissions =
android.api = 35
android.minapi = 23
android.archs = arm64-v8a, armeabi-v7a
p4a.bootstrap = sdl2
p4a.url = https://github.com/AnGlonchas/python-for-android.git
p4a.branch = develop

[buildozer]
log_level = 2
warn_on_root = 1
