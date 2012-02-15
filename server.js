require("coffee-script");
require("./app").listen(process.env.PORT || 8080);

console.log("Listening on port %d", process.env.PORT || 8080)