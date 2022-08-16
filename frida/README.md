# Frida
My fav cheatsheet :]

## Android
List installed apps:
```
frida-ps -Uia
```

Trace everything from already loaded, front-most app using filter for class `fi.tk0.fridatesting.StringsTest` containing any method starting with `get`:
```
frida-trace -U -F -j 'fi.tk0.fridatesting.StringsTest!get*'
```

## iOS
List installed apps:
```
frida-ps -Uia
```

Trace everything from $APP application (e.g. `APP="com.apple.mobilenotes"`) class `SuperEncryption` with any (wildcard) ObjC-method:
```
frida-trace -U -m "*[*SuperEncryption* *]" -f $APP
```

Trace all embedded browser related stuff and forward everthing into log:
```
frida-trace -U -m "*[UIWebView *]" -m "*[WKWebView *]" -m "*[SFSafariView* *]" -m "*[ASWeb* *]" -f $APP -o frida_trace.log
```

Instrument by loading $APP and using our `our-funcs.js` during runtime:
```
frida -U --no-pause -l our-funcs.js -f $APP
```
