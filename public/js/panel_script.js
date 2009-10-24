$(document).ready(function() {

  // Initialize the appearance of block-selector 0
  $('.block-selector').eq(0).toggleClass('block-selected',true);

  // The panels display requires the menu to be fixed
  $("#menu-wrapper, #blocksmenu").css("position","fixed");

  // Offsets the blocks&images so that it doesn't overlap with the fixed menu.
  // If the height of the menu was known, a static css properly would work.
  $('#blocksmenu').css({'margin-top':$('#menu-wrapper').height()});
  $('#document').css({'padding-top':$('#menu-wrapper').height()+$('#blocksmenu').innerHeight()+'px'});

  // Animation for putting an image back to normal state
  $.fn.extend({
    shrink: function() {
      return $(this, document).animate({
        "width": "100px",
        "height":"75px",
        "marginLeft":"0px",
        "marginTop":"0px"
      },
        750);
  }});

  // A container for every image's metadata
  details_store = {};

  // We pre-store the width of the tooltip. Too bad if text size changes.
  var tooltip_half_width = $('#tooltip').width()/2;

  // Browsers handle window scrolling differently.
  // Chrome and Safari use <body>, while Opera, FF and IE use <html>
  // Warning: this doesn't seem to be future-proof. $.browser.safari might return false for Chrome some day.
  var scrollable = $.browser.safari ? 'body' : 'html';

  // By Jonathan Howard
  $.fn.pause = function(milli,type) {
    milli = milli || 1000;
    type = type || "fx";
    return this.queue(type,function(){
      var self = this;
      setTimeout(function(){
        $.dequeue(self);
    },milli);
    });
  };

  function show_tooltip() {
    $('#tooltip').css({"display":"block"}).stop().animate({"opacity":"0.8"},500);
  }

  function hide_tooltip() {
    $('#tooltip').stop().animate({"opacity":"0"},500,function(){ $(this).css({"display":"none"});});
  }

  // Updates the markup showing current image's details
  function change_tooltip(image_id) {
    $('#tooltip-title').text(details_store[image_id].title);
  }

  function hide_details() {
    $('#details').fadeOut();
  }

  function change_details(image_id) {
    $('#details-title', '').text(details_store[image_id].title);
    $('#details-collection a').attr('href', details_store[image_id].url).text(details_store[image_id].collection);
    $('#details-collection').show();
  }

  function widen(image) {
    // Comment ref 001
    // IE7 needs the following line
    // See http://www.quirksmode.org/bugreports/archives/2006/01/Explorer_z_index_bug.html
    $(image).parent().css("z-index", "2500");

    $(image).stop().css("z-index", "2500").animate({
      "width": "200px",
      "height":"150px",
      "marginLeft":"-50px",
      "marginTop":"-37px"
      },
      750
    );
  }

  function smallen(image) {
    $(image).parent().css("z-index", "2");
    $(image).stop().css("z-index","2").animate({
      "width": "100px",
      "height":"75px",
      "marginLeft":"0px",
      "marginTop":"0px"
    },
      750, function() {
        $(this).parent().css("z-index", "1");
        $(this).css("z-index", "1");
    });

  }

  // The image currently enlarged.
  var big_img;

  // A block is a small grid of images.

  // The id of the block currently clicked.
  var current_block_id = 0;

  // Go from current_block_id to new_block_id
  // offset argument is optional; the caller might include it if it has a faster way to compute it.
  function select_block(new_block_id,offset) {
    new_block_id = parseInt(new_block_id);

    if (new_block_id != current_block_id) {
      var offset = offset || $('.imgblock').eq(new_block_id).offset().left;
      $(scrollable).stop().animate({scrollLeft: offset-25}, 500);

      $('.block-selector').eq(current_block_id).toggleClass('block-selected',false);
      current_block_id = new_block_id;
      $('.block-selector').eq(current_block_id).toggleClass('block-selected',true);
    }
  }

  // Special info box to help the user who enlarged a picture
  $('body').append('<div id="help-box">Click again to shrink the image.</div>')

  $().mousemove(
    function(event) {

      $('#tooltip').css({
        "top":event.pageY + 50,
        "left": (event.pageX > tooltip_half_width ? event.pageX - tooltip_half_width : 0) + 15
      });
    }
  );

  $('.imgblock').mouseleave(
    function(event) {
      hide_tooltip();
    }
  );

  $('img').hover(
    function() {
      if (big_img != this) {
        change_tooltip($(this).parent().attr('id'));
        show_tooltip();
        widen(this);
      } else {
        hide_tooltip();
      }
    },
    function() {
        if (big_img != this) {
          smallen(this);
        }
      }
    );

  $('img').click(
    function() {
      var iid = $(this).parent().attr('id');
      if (big_img == this) {
        $(this).stop().shrink();
        $('#help-box').stop(true,false).fadeOut(500);
        hide_details();
        $('#tooltip').show();
        big_img = undefined;
      } else {
        var self = this
        var image = new Image();
        $(image).load(function() {
          $(self).attr('src',details_store[iid].fullres_url);
        });
        image.src = details_store[iid].fullres_url;

        var current_position = $(this).offset();
        var dest_position = $(this).parent().parent().offset();

        var margin_x = current_position.left - dest_position.left;
        var margin_y = current_position.top - dest_position.top;

        $(this).parent().css("z-index", "3000"); // See comment #001
        $(this).stop().css("z-index","3000").animate({
          "width": "600px",
          "height": "450px",
          "marginTop":"-="+margin_y,
          "marginLeft":"-="+margin_x},
          750,
          function() {
            $('#help-box').css({
              'left':dest_position.left+"px",
              'top':dest_position.top+450+'px'}).pause(200).fadeIn(2000).pause(8000).fadeOut(1000);


            change_details(iid);
            $('#details').fadeIn().css({'left':dest_position.left+'px', 'top':dest_position.top+(450-40-$('#details').height())+'px'});
          });

        if (big_img != undefined) {
          $(big_img).shrink();
        }

        big_img = this;

        hide_tooltip();

        var $block = $(this).parent().parent();
        var new_block_id = parseInt($block.attr('id').substring(1));
        var offset = $block.offset().left;
        select_block(new_block_id,offset);
      }

    });

    $('.block-selector').click(
      function() {
        var new_block_id = $(this).attr('id').charAt(2);
        select_block(new_block_id);
        return false;
      });

    $('#prev-block').click(
      function() {
        (current_block_id > 0) ? select_block(current_block_id-1) : select_block(max_block_id);
        return false;
      });

    $('#next-block').click(
    function() {
      (current_block_id < max_block_id) ? select_block(current_block_id+1) : select_block(0);
      return false;
    });

  // DEVELOPMENT UTILITIES

  // function update_z_status() {
  //   $(".zindex").each(function() {
  //     var k = $(this).parent().find("img").css('z-index');
  //     $(this).text(k);
  //     });
  //   }
  //
  //   $(window).keydown(
  //     function(event) {
  //       switch(event.keyCode) {
  //         case 90: // Letter "z"
  //           update_z_status();
  //           return false;
  //       }
  //     }
  //   );
  //
});