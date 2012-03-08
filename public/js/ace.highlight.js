var EditSession = require("ace/edit_session").EditSession;
var TextLayer = require("ace/layer/text").Text;
var baseStyles = "";//require("ace/requirejs/text!./static.css");

/** Transforms a given input code snippet into HTML using the given mode
*
* @param {string} input Code snippet
* @param {mode} mode Mode loaded from /ace/mode (use 'ServerSideHiglighter.getMode')
* @param {string} r Code snippet
* @returns {object} An object containing: html, css
*/

window.staticHighlight = function(input, mode, theme, lineStart) {
    lineStart = parseInt(lineStart || 1, 10);
    
    theme || (theme = require("ace/theme/textmate"));
    //mode || (mode = require("ace/mode/text"));
    
    var session = new EditSession("");
    if (mode) {
      session.setMode(mode);
      session.setUseWorker(false);
    }
    
    var textLayer = new TextLayer(document.createElement("div"));
    textLayer.setSession(session);
    textLayer.config = {
        characterWidth: 10,
        lineHeight: 20
    };
    
    session.setValue(input);
            
    var stringBuilder = [];
    var length =  session.getLength();
    var tokens = session.getTokens(0, length - 1);
    
    for(var ix = 0; ix < length; ix++) {
        var lineTokens = tokens[ix].tokens;
        stringBuilder.push("<div class='ace_line'>");
        //stringBuilder.push("<span class='ace_gutter ace_gutter-cell' unselectable='on'>" + (ix + lineStart) + "</span>");
        textLayer.$renderLine(stringBuilder, 0, lineTokens, true);
        stringBuilder.push("</div>");
    }
    
    // let's prepare the whole html
    var html = "<div class=':cssClass'>\
        <div class='ace_editor ace_scroller ace_text-layer'>\
            :code\
        </div>\
    </div>".replace(/:cssClass/, theme.cssClass).replace(/:code/, stringBuilder.join(""));
        
    textLayer.destroy();
            
    return {
        css: baseStyles + theme.cssText,
        html: html
    };
};