cd client/elm && npx light-server -s ../static -p 8000 -w "**/*.elm # elm make daycare.elm --output=../static/main.js" -w "../static/**/*.css" -x http://localhost:5000/ --proxypath "/api"