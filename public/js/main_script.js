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

  // Hides a selector if the user clicks outside of it
  $(document).click(function(e) {
    // Checks whether a selector is among the parents of the clicked element.
    // ...or if the user clicked on a selector's tab.
    if ($.inArray( $('.selector').get(0), $(e.target).parents()) == -1 && e.target.className.search('filter-option') == -1) {
      $('.filter-option').toggleClass('filter-option-activated',false);
      $('.selector').css({"visibility":"hidden"});
    }
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
    
    var style = $("form#search input[name='st']").attr('value');
    $("input[name='st']").attr('st',style);
  }); 
  
});