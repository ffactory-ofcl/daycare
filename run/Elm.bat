cd ../client
npx light-server -s . -p 8000 -o -w "**/*.elm # elm make daycare.elm --output=main.js # reload" -w "**.css # # reloadcss"