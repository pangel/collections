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

  // The image currently enlarged.
  var big_img;

  // A block is a small grid of images.

  // The id of the block currently clicked.
  var current_block_id = 0;

  // Updates the markup showing current image's details
  function show_details(image_id) {
    $('#imgtitle').text(details_store[image_id].title);
    $('#imgcol a').attr('href', details_store[image_id].collection_url).text(details_store[image_id].collection);
    $('#imglink').attr('href', details_store[image_id].url);
  }

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

  $('img').hover(
    function() {
      if (big_img != this) {
        $(this).stop().css("z-index", "2500").animate({
          "width": "200px",
          "height":"150px",
          "marginLeft":"-50px",
          "marginTop":"-37px"
          },
          750
        );
      }
    },
    function() {
        // Will need to wrap this into a jQuery.fn.extend(..)
        // If I want to be able to call it at other places, in other times
        // Alternatively, see "jQuery custom animations"
        if (big_img != this) {
          $(this).stop().css("z-index","2").animate({
            "width": "100px",
            "height":"75px",
            "marginLeft":"0px",
            "marginTop":"0px"
          },
            750, function() {
              $(this).css("z-index", "1");
          });
        }
      }
    );

  $('img').click(
    function() {
      // Save the div to avoid multiple DOM lookups.
      var details = $("#details", document);

      if (big_img == this) {
        $(this).stop().shrink();
        $('#help-box').stop(true,false).fadeOut(500);
        details.stop().animate({"right":"-340px","visibility":"hidden"});

        big_img = undefined;
      } else {
        var current_position = $(this).offset();
        var dest_position = $(this).parent().parent().offset();

        var margin_x = current_position.left - dest_position.left;
        var margin_y = current_position.top - dest_position.top;

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
            }
          );

        if (big_img != undefined) {
          $(big_img).shrink();
        }

        big_img = this;

        iid = $(this).parent().attr('id');

        if(details.css("right") == "-340px") {
          show_details(iid);
          details.css("visibility", "visible")
          details.animate({"right":"0"});

        } else {
          details.find('p').hide();
          show_details(iid);
          details.find('p').fadeIn(750);
        }

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