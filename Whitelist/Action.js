//
//  Action.js
//  Whitelist
//
//  Created by MoonSung Wook on 2015. 9. 20..
//  Copyright © 2015년 smoon.kr. All rights reserved.
//

var Action = function() {};

Action.prototype = {
    run: function(arguments) {
        arguments.completionFunction({ "domain" : location.hostname });
    },
    
    finalize: function(arguments) {
        location.reload(true);
    }
    
};
    
var ExtensionPreprocessingJS = new Action
