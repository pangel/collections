$(document).ready(function() {
  
  // Initialize the appearance of block-selector 0
  $('.block-selector').eq(0).toggleClass('block-selected',true);


  // Offsets the blocks&images so that it doesn't overlap with the fixed menu.
  // If the height of the menu was known, a static css properly would work.

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

  // Pointer to the container for full-resolutions images
  var details_image = $('#details-image');

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
    $('#details').animate({"opacity":"0"},500);
  }

  function change_details(image_id) {
    $('#details-title', '').text(details_store[image_id].title);
    $('#details-collection a').attr('href', details_store[image_id].url).text(details_store[image_id].collection);
    $('#details-collection, #details-title').show();
  }

  function widen(image) {
    // Comment ref 001
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
      var offset = offset || $('.imgblock').eq(new_block_id).offset().top;
      $(scrollable).stop().animate({scrollTop: offset-25}, 500);

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

  $('#document img').hover(
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

  $('#document img').click(
    function() {
      var iid = $(this).parent().attr('id');
      
      if (details_image.attr('src') === $(this).attr('src')) {
        $(this).stop().shrink();
      } else {
        crossfade_details_image($(this).attr('src'), function() {
          crossfade_details_image(details_store[iid].fullres_url);
        });
        
        change_details(iid);

        smallen(this);
        
        if (big_img != undefined) {
          $(big_img).fadeTo("normal", 1);
        }
        
        big_img = this;
        $(big_img).fadeTo("normal", 0.33);        

        hide_tooltip();
        
        var $block = $(this).parent().parent();
        var new_block_id = parseInt($block.attr('id').substring(1));
        var offset = $block.offset().top;
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
    
    function crossfade_details_image(url,callback) {
      var $back = $('#details-image-back');
      var $front = $('#details-image');
      
      $back.stop().fadeTo(0,0).unbind("load").load(function() {
        $back.fadeTo("slow",1);
        $front.fadeTo("slow",0, function() {
          $front.unbind("load").load(function() {
            $front.fadeTo("slow",1, function() {
              if (typeof(callback) === 'function') {
                callback.call(this);
              }
            });
          });
          $front.attr('src', url)
        });
      });
      $back.attr('src', url);
    }

});