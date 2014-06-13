var data;
var show_date;
var show_featured;

function get_state(name) {
	var state = localStorage.getItem(name);	
	if (state === null) {
		state = false;
	} else {
		state = JSON.parse(state);
	}
	return state;
}

function toggle() {
	//console.log(this.id);
	var state = get_state(this.id);
	state = ! state;
	localStorage.setItem(this.id, state);

	if (this.id == 'show_featured') {
		show('show_featured', 'featured');
	}
	if (this.id == 'show_date') {
		show('show_date', 'date');
	}
}

function show(id, cls) {
	var state = get_state(id);
	var elements = document.getElementsByClassName(cls);
	for (var i=0; i < elements.length; i++) {
		elements[i].style.display = state ? 'inline' : 'none';
	};
}

function sort_rows() {
	console.log('sort: ' + this.id);
	var column = 2; // title
	if (this.id == 'sort_date') {
		column = 0;
	}
	if (this.id == 'sort_featured') {
		column = 1;
	}
	if (this.id == 'sort_title') {
		column = 2;
	}

	var ch = document.getElementById('videos').children;
	//console.log(ch.length);
	var html = '<li>' + ch[0].innerHTML + '</li>';
	//console.log(html);

	//var sort_descending = get_status('sort_descending');

	var arr = new Array;
	for (var i = 1; i < ch.length; i++) {
		arr.push({
			"field" : ch[i].children[column].innerHTML,
			"html"  : ch[i].innerHTML
		});
	}
	arr.sort(function(a, b) { return a['field'].localeCompare(b['field']) });
	html += arr.map(function(a) { return '<li>' + a['html'] + '</li>' }).join('');
	//console.log(html);
	document.getElementById('videos').innerHTML = html;
	add_listeners();
}


function on_load() {
	show_date     = document.getElementById('show_date');
	show_date.addEventListener('click', toggle);
	show('show_date', 'date');
	show_featured = document.getElementById('show_featured');
	show_featured.addEventListener('click', toggle);
	show('show_featured', 'featured');

	add_listeners();
}
function add_listeners() {
	if (document.getElementById('sort_date') == undefined) {
		return; // pages without lists
	}
	document.getElementById('sort_date').addEventListener('click', sort_rows);
	document.getElementById('sort_featured').addEventListener('click', sort_rows);
	document.getElementById('sort_title').addEventListener('click', sort_rows);
}

on_load();

