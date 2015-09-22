//
//  Action.js
//  Quick Report
//
//  Created by MoonSung Wook on 2015. 9. 22..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

var Action = function() {};

Action.prototype = {
    run: function(arguments) {
        arguments.completionFunction({ "url" : location.href });
    },
    
    finalize: function(arguments) {
        alert(arguments["message"]);
    }
    
};
    
var ExtensionPreprocessingJS = new Action
