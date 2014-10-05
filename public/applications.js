var parseColor = function() {

    var colors = [
      "#FFFFFF",
      "#000000",
      "#000080",
      "#008000",
      
      "#ff0000",
      "#800040",
      "#800080",
      "#ff8040",
      
      "#ffff00",
      "#80ff00",
      "#008000",
      "#00ffff",
      
      "#0000ff",
      "#FF55FF",
      "#808080",
      "#C0C0C0"
    ];

    var style = {
      2 : {
        styles : [
          {
            key : "font-weight",
            value : "bold"
          }
        ]
      },
      15: {
        styles : [
          {
            key : "background",
            value : null
          },
          {
            key : "color",
            value : null
          },
          {
            key : "font-style",
            value : null
          },
          {
            key : "text-decoration",
            value : null
          },
          {
            key : "font-weight",
            value : null
          }
        ]
      },
      22: {
        styles:[]
      },
      29: {
        styles : [
          {
            key : "font-style",
            value : "italic"
          }
        ]
      },
      31: {
        styles : [
          {
            key : "text-decoration",
            value : "underline"
          }
        ]
      },
      3 : function(str){
        var temp, color, background,style
        style = [];
        temp = str.substring(1).split(",")
        color = colors[parseInt(temp[0])];
        if (color) {
          style.push({
            key : "color",
            value : color
          })
        }
        if (temp[1]) {
          background = colors[parseInt(temp[1])];
          if (background) {
            style.push({
              key : "background",
              value : background
            })
          }
        }
        
        return {
          styles : style
        };
        
      }
    }

    function copyOver(from, to) {
      for(var i in from) {
        if(from.hasOwnProperty(i)) {
          to[i] = from[i];
        }
      }
    }

    function wrap(text, styles) {
      if (text == null) {
        return "";
      }
      var i
      var text2 = "<span style='"
      for (i in styles) {
        if (styles.hasOwnProperty(i)) {
          text2 += i;
          text2 += ":";
          text2 += styles[i];
          text2 += ";";
        }
      }
      text2 += "'>";
      text2 += text;
      text2 += "</span>";
      return text2;
    }
    
    var parseColor_ = function(html) {
        
        var html, matchrule, matchrule2, allStyle, temp, text, styles, stylefrag, i;
        allStyle = [2, 15, 22, 29, 31, 3];
        matchrule = /((?:\u0003\d\d?,\d\d?|\u0003\d\d?|\u0002|\u001d|\u000f|\u0016|\u001f)+)/g;
        /* use "html" to prevent break links*/
        //html = $(this).html();
        temp = html.split(matchrule);
        if (temp.length === 1) {
          /*no color code, so break it at early at possible*/
          return html;
        }
        for (i = 0; i < temp.length; i++) {
          text = temp[i];
          if (allStyle.indexOf(text.charCodeAt(0)) < 0) {
            continue;
          }
          styles = {};
          matchrule2 = /((?:\u0003\d\d?,\d\d?|\u0003\d\d?|\u0002|\u001d|\u000f|\u0016|\u001f))/g;
          fragTemp = matchrule2.exec(text);
          
          if (!fragTemp) {
            continue;
          }
          
          stylefrag = [];
          stylefrag.push(fragTemp[1]);
          while (fragTemp = matchrule2.exec(text)) {
            stylefrag.push(fragTemp[1]);
          }
          
          // extract styles from style frag
          stylefrag.forEach(function(el){
            var temp2, i
            var charCode = el.charCodeAt(0);
            if (style[charCode]) {
              temp2 = style[charCode]
              if (typeof temp2 === "function") {
                temp2 = temp2(el);
              }
              for (i = 0; i< temp2.styles.length; i++) {
                styles[temp2.styles[i].key] = temp2.styles[i].value;
              }
            }
            return true;
          });
          //console.log(JSON.stringify(text));
          //console.log(JSON.stringify(stylefrag));
          //insert styles into list and remove parsed tag
          temp.splice(i, 1, styles);
        }
      
        
        
        var styleTemp = {};
        for (i = 0; i < temp.length; i++) {
          if (typeof temp[i] === "object") {
            copyOver(temp[i], styleTemp);
            copyOver(styleTemp, temp[i]);
          }
        }
      
        for (i = 0; i < temp.length; i++) {
          if (typeof temp[i] === "object") {
            temp.splice(i, 2, wrap(temp[i + 1], temp[i]));
          }
        }
      
        return temp.join('')
    
    };
    
    return parseColor_;
} ();

var getColor = function() {
  var cache = {};
  function getColor_(str) {
    if (cache[str]) {
      return cache[str];
    }
    
    if (typeof md5 !== "undefined") {
      var frag = parseInt(md5(str).substring(0,6), 16);
    } else {
      var frag = Math.floor(Math.random() * 0xffffff);
      console.log('missing md5 support, using random color now!')
    }
    
    var h = Math.floor((frag & 0xff0000 >> 16) / 255 * 360);
    var s = Math.floor((frag & 0xff00 >> 8) / 255 * 60 + 20);
    var l = Math.floor((frag & 0xff) / 255 * 20 + 50);
    
    //convert color with jQuery
    var colorCode = $('<span></span>').css("color", "hsl(" + h + "," + s + "%," + l +"%)").css("color");
    
    cache[str] = colorCode;
    return colorCode;
  }
  return getColor_;
}();

setTimeout(function(){
  $("ul.logs li").each(function(){
    var nickField = $(this).children(".nick");
    
    nickField.css("color",getColor(nickField.text()));
  });
  $(".wordwrap").each(function(){
    $(this).html(
      parseColor($(this).html())
    );
  });
} ,100);

var strftime = function(date) {
  var hour = date.getHours(),
      min  = date.getMinutes(),
      sec  = date.getSeconds();

  if (hour < 10) { hour = "0" + hour; }
  if ( min < 10) {  min = "0" +  min; }
  if ( sec < 10) {  sec = "0" +  sec; }

  return hour + ":" + min + ":" + sec;
};

var link = function(klass, href, title) {
  return $('<a class="' + klass + '" href="' + href
    + '" target="_self" title="' + title + '">');
};

var lastTimestamp = undefined;
var seenTimestamp = {};
var pollNewMsg = function(isWidget) {
  var isWidget = (isWidget == null) ? false : isWidget;
  var time = lastTimestamp || (new Date()).getTime() / 1000.0;
  $.ajax({
    url: "/comet/poll/" + channel + "/" + time + "/updates.json",
    type: "get",
    async: true,
    cache: false,
    timeout: 60000,

    success: function (data) {
      var msgs = JSON.parse(data || '[]');
      for (var i = 0; i < msgs.length; i++) {
        var msg = msgs[i];
        if (seenTimestamp[msg.time]) { continue; }
        seenTimestamp[msg.time] = true;
        var date = new Date(parseFloat(msg["time"]) * 1000);
        var lis  = $(".logs > li").length;
        var url  = $("#today").text();
        
        // $("#today").text() gets nothing automatically when isWidget
        var msgElement = $("<li id=\"" + lis + "\">").addClass("new-arrival")
          .append(link('time', url + '#' + lis, '#' + lis)
                    .text(strftime(date)))
          .append(link('nick', url + '/' + lis, msg['nick'])
                    .text(msg['nick'])
                    .css("color",getColor(msg['nick'])))
          .append($("<span class=\"msg wordwrap\">").html(msg["msg"]).each(function(){
            $(this).html(
              parseColor($(this).html())
            );
          }));
        if (isWidget) {
          $(".logs").prepend(msgElement);
        }
        else {
          $(".logs").append(msgElement);
        }
      }

      // there's new message
      if (msgs.length > 0) {
        if (isWidget) {
          // widget layout
          $(document).scrollTop(0);
        }
        else {
          // desktop or mobile layout, there's a switch to turn off auto-scrolling
          if (window.can_scroll) {
            $(document).scrollTop($(document).height());
          }
        }

        // if we're in desktop version
        if (typeof Cocoa !== "undefined" && Cocoa !== null) {
          Cocoa.requestUserAttention();
          Cocoa.addUnreadCountToBadgeLabel(msgs.length);
        }
      }
lastTimestamp = (new Date()).getTime() / 1000.0;
try {
      lastTimestamp = msgs[msgs.length - 1]["time"];
} catch (e) {};

setTimeout(function(){
      pollNewMsg(isWidget);
}, 3000);
    },

    error: function() {
setTimeout(function(){
      pollNewMsg(isWidget);
}, Math.round(Math.random() * 3000 + 3000));
    }
  });
}

var enableDatePicker = function() {
  var useJqueryUIDatePicker = !Modernizr.inputtypes.date;
  
  $('#date-picker').on('change', function(event) {
    var targetDate = this.value;
    if (targetDate !== 'other') {
      location.href = location.href.replace(/[^\/]+$/, targetDate);
    } else {
      $( "#other-date-dialog" ).dialog( "open" );
    }
  });
  $( "#other-date-dialog" ).dialog({
    autoOpen: false,
    resizable: false,
    height:280,
    width:360,
    modal: true,
    open: function (event, ui) {
      if (useJqueryUIDatePicker) {
        if ($( ".ui-datepicker" ).is( ":visible" )) {
          $( "#other-date-picker" ).datepicker( "disable" );
        }
        $( "#other-date-picker" ).datepicker( "enable" );
      }
      $( "#other-date-picker" ).val( currentDay );
    },
    buttons: {
      "cancel": function() {
        $( this ).dialog( "close" );
      },
      "go": function() {
        $( this ).dialog( "close" );
        var targetDate = $( "#other-date-picker" ).val();
        location.href = location.href.replace(/[^\/]+$/, targetDate);
      }
    },
    beforeClose: function() {
      $( "#other-date-picker" ).datepicker("disable");
      if ($("#today").text() === currentDay) {
        $( "#date-picker" ).val( "today" );
      } else {
        $( "#date-picker" ).val( currentDay );
      }
    }
  });
  $( "#other-date-picker" ).on ( "keydown", function(e) {
    $( "#other-date-picker" ).datepicker( "hide" );
    if(e.which == 13) {
      $( "#other-date-dialog" ).dialog( "close" );
      $( "#date-picker" ).val( currentDay );
      var targetDate = $("#other-date-picker").val();
      location.href = location.href.replace(/[^\/]+$/, targetDate);
    }
  });
  
  var enableJqueryUIDatePicker = function() {
    var $input = $( "#other-date-picker" );
    /**
    IE sucks
    http://stackoverflow.com/questions/13010463/avoid-reopen-datepicker-after-select-a-date
    */
    $( "#other-date-picker" ).datepicker({
      fixFocusIE: false,    
      onSelect: function(dateText, inst) {
        this.fixFocusIE = true
        $(this).change().focus();
      },
      onClose: function(dateText, inst) {
        this.fixFocusIE = true;
        this.focus();
      },
      beforeShow: function(input, inst) {
        var result = $.browser.msie ? !this.fixFocusIE : true;
        this.fixFocusIE = false;
        return result;
      }
    });
    $( "#other-date-picker" ).datepicker( "option", "dateFormat", "yy-mm-dd");
    $( "#other-date-picker" ).datepicker( "option", "maxDate", today );
    $( "#other-date-picker" ).datepicker( "option", "showAnim", "" );
    $( "#other-date-picker" ).datepicker("disable");
  }

  if (useJqueryUIDatePicker) {
    enableJqueryUIDatePicker();
  }
}

enableDatePicker();

$(".scroll_switch").click(function() {
  window.can_scroll = $(".scroll_switch").hasClass("scroll_switch_off");
  $(".scroll_switch").toggleClass("scroll_switch_off");
});

var pageScrollTop = function(position) {
  $("html, body").animate({
    scrollTop: position
  }, 1000);
};
