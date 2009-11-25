$(document).ready(function() {

  $('.filter-option').hover(function() {
    $('.filter-option').toggleClass('filter-option-activated',false);
    $('.selector').css({"visibility":"hidden"});

    $(this).toggleClass('filter-option-activated',true);
    var selector_id = '#'+$(this).get(0).id.split('-')[1]+'-selector';
    $(selector_id).css({"visibility":"visible"});
  });

  $('.selector-actions a').click(function() {
    var this_type = $(this).get(0).id.split('-')[1];
    var tab_id = '#filter-'+ this_type;
    var selector_id = '#' + this_type + '-selector';

    $(tab_id).toggleClass('filter-option-activated',false);
    $(selector_id).css({"visibility":"hidden"});
  });

  // Activate all sources of a category when that category is clicked on.
  $('.selector-column').click(function () {
    if ($(this).attr('enabled') === 'true') {
      $(this).css('background-color', '#fff');
      $('input',this).attr('checked',false);
      $(this).attr('enabled','false');
    } else {
      $(this).css('background-color', '#ddd');
      $('input',this).attr('checked',true);
      $(this).attr('enabled','true');
    }
  });

  // Hides a selector if the user clicks outside of it
  $(document).click(function(e) {
    // Checks whether a selector is among the parents of the clicked element.
    // ...or if the user clicked on a selector's tab.
    if ($.inArray( $('.selector').get(0), $(e.target).parents()) == -1 && e.target.className.search('filter-option') == -1) {
      $('.filter-option').toggleClass('filter-option-activated',false);
      $('.selector').css({"visibility":"hidden"});
    }
  });

  $('#submit-search').click(function() {
    $('form#search').submit();
    return false;
  });

  $('#select-all').click(function() {
    $('li input').attr('checked',true);
    return false;
  });

  $('#reset').click(function() {
    $('li input').attr('checked',false);
    return false;
  });

  $('form.selector').submit(function() {
    var query = $("form#search input[name='q']").attr('value');
    $("input[name='q']").val(query);

    var format = $("form#search select[name='f'] option[selected]").attr('value');
    $("input[name='f']").val(format);
  });

  // From http://lite.piclens.com/current/piclens.js
  function hasCooliris() {
		var clientExists = false;
		if (window.piclens && window.piclens.launch) {
			clientExists = true;
		} else {
			var context = null;
			if (typeof PicLensContext != 'undefined') { // Firefox
				context = new PicLensContext();
			} else {									
				try {
					context = new ActiveXObject("PicLens.Context"); // IE
				} catch (e) {
					if (navigator.mimeTypes['application/x-cooliris']) { // Safari
						context = document.createElement('object');
						context.style.height="0px";
						context.style.width="0px";
						context.type = 'application/x-cooliris';
						document.documentElement.appendChild(context);
					} else {
						context = null;
					}
				}
			}
			
			this.PLC = context;
			if (context) {
				clientExists = true;
			}
		}
    return clientExists;
  }
  //if (!hasCooliris()) { alert ("You can install Cooliris you know :-)"); }

});