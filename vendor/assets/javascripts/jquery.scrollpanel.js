/* jQuery.scrollpanel 0.5.0 - http://larsjung.de/jquery-scrollpanel/ */
!function(){"use strict";function o(o,t){var s=this;s.$el=e(o),s.settings=e.extend({},r,t);var n=s.settings.prefix;s.mouseOffsetY=0,s.updateId=0,s.scrollProxy=e.proxy(s.scroll,s),s.$el.css("position")&&"static"!==s.$el.css("position")||s.$el.css("position","relative"),s.$scrollbar=e('<div class="'+n+'scrollbar"/>'),s.$thumb=e('<div class="'+n+'thumb"/>').appendTo(s.$scrollbar),s.$el.addClass(n+"host").wrapInner('<div class="'+n+'viewport"><div class="'+n+'container"/></div>').append(s.$scrollbar),s.$viewport=s.$el.find("> ."+n+"viewport"),s.$container=s.$viewport.find("> ."+n+"container"),s.$el.on("mousewheel",function(o,e,t,r){s.$viewport.scrollTop(s.$viewport.scrollTop()-50*r),s.update(),o.preventDefault(),o.stopPropagation()}).on("scroll",function(){s.update()}),s.$viewport.css({paddingRight:s.$scrollbar.outerWidth(!0),height:s.$el.height(),overflow:"hidden"}),s.$container.css({overflow:"hidden"}),s.$scrollbar.css({position:"absolute",top:0,right:0,overflow:"hidden"}).on("mousedown",function(o){s.mouseOffsetY=s.$thumb.outerHeight()/2,s.onMousedown(o)}).each(function(){s.onselectstart=function(){return!1}}),s.$thumb.css({position:"absolute",left:0,width:"100%"}).on("mousedown",function(o){s.mouseOffsetY=o.pageY-s.$thumb.offset().top,s.onMousedown(o)}),s.update()}var e=jQuery,t=e(window),s="scrollpanel",r={prefix:"sp-"};e.extend(o.prototype,{update:function(o){var e=this;e.updateId&&!o?(clearInterval(e.updateId),e.updateId=0):!e.updateId&&o&&(e.updateId=setInterval(function(){e.update(!0)},50)),e.$viewport.css("height",e.$el.height());var t=e.$el.height(),s=e.$container.outerHeight(),r=e.$viewport.scrollTop(),n=r/s,i=Math.min(t/s,1),l=e.$scrollbar.height();1>i?(e.$scrollbar.css({height:e.$el.innerHeight()+l-e.$scrollbar.outerHeight(!0)}).fadeIn(50),e.$thumb.css({top:l*n,height:l*i})):e.$scrollbar.fadeOut(50)},scroll:function(o){var e=this,t=(o.pageY-e.$scrollbar.offset().top-e.mouseOffsetY)/e.$scrollbar.height();e.$viewport.scrollTop(e.$container.outerHeight()*t),e.update(),o.preventDefault(),o.stopPropagation()},onMousedown:function(o){var e=this;e.scroll(o),e.$scrollbar.addClass("active"),t.on("mousemove",e.scrollProxy).one("mouseup",function(o){e.$scrollbar.removeClass("active"),t.off("mousemove",e.scrollProxy),e.scroll(o)})}}),e.fn[s]=function(t,r){return this.each(function(){var n=e(this),i=n.data(s);i||(i=new o(this,t),i.update(),n.data(s,i)),"update"===t&&i.update(r)})}}();