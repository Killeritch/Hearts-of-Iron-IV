function hoi4WikiStyleLink() {
  var link = document.createElement('link');
  link.type = 'text/css';
  link.rel = 'stylesheet';
  link.href = 'http://www.hoi4wiki.com/top_secret.css';

  var head = document.getElementsByTagName('head')[0];
  head.appendChild(link);
}

function hoi4WikiStyle() {
  var style = document.createElement('style');
  style.type = 'text/css';
  style.innerHTML = '\
	footer, #mw-panel, #left-navigation, #p-personal, #p-views, #p-cactions {\
		display:none;\
	}\
	\
	.mw-body {\
		margin-left: 0;\
	}\
	\
	#right-navigation {\
		margin-top: 0;\
	}\
	\
	#mw-page-base {\
		height: 1.5em;\
	}\
	';

  var head = document.getElementsByTagName('head')[0];
  head.appendChild(style);
}

hoi4WikiStyle();
