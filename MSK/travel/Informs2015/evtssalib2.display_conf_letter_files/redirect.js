$(document).ready(function() {
  var redirect = location.href;
  // need to redirect shopping cart addition to https://online.informs.org/informsssa/ecquicklinks.link_to_edit_shopping_cart
  if (redirect.indexOf('ecssashop.add_to_shopping_cart') > -1) redirect = 'https://online.informs.org/informsssa/ecquicklinks.link_to_edit_shopping_cart';
  else if (redirect.indexOf('censsadynoverview.display_page?p_context_cd=REDIRECT') > -1) redirect = Cookies.get("remember_page");
  document.cookie = 'remember_page=' + escape(redirect) + ';domain=.informs.org;path=/';
  //if (Cookies.get("SSAAUTHMAIN.LOGIN_PAGE.SUCCESS_URL")=="") Cookies.set("SSAAUTHMAIN.LOGIN_PAGE.SUCCESS_URL", "censsadynoverview.display_page");
});
function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}